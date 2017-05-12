# Casablanca Stock Exchange setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Suffix::CAS;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Download;
use App::Chart::FinanceQuote;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


# Casablanca post 1978 is GMT with no daylight savings, so
# Time::TZ->tz_known() can't tell if it's ok
my $timezone_casablanca = App::Chart::TZ->new
  (name => __('Casablanca'),
   tz   => 'Africa/Casablanca');

my $pred = App::Chart::Sympred::Suffix->new ('.CAS');
$timezone_casablanca->setup_for_symbol ($pred);
App::Chart::setup_source_help
  ($pred, __p('manual-node','Casablanca Stock Exchange'));


#------------------------------------------------------------------------------
# weblink - company info
#
# French or English
#  http://www.casablanca-bourse.com/cgi/ASP/Fiches/fiche.asp?TICKER=NEJ
#  http://www.casablanca-bourse.com/cgi/ASP/Fiches/anglais/fiche.asp?TICKER=NEJ

App::Chart::Weblink->new
  (pred => $pred,
   name => __('Casablanca _Company Information'),
   desc => __('Open web browser at the Casablanca Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (fr => '',
                                                  en => '/anglais');
     return "http://www.casablanca-bourse.com/cgi/ASP/Fiches$lang/fiche.asp?TICKER=$symbol";
   });


#-----------------------------------------------------------------------------
# latest quotes, using Finance::Quote::Casablanca

App::Chart::FinanceQuote->setup (pred => $pred,
                                suffix => '.CAS',
                                modules => ['Casablanca'],
                                method => 'casablanca',
                                max_symbols => 1);

# ;; return current Casablanca adate/time, with 15-minute delay
# ;; pre-open 9:00am through to closure 15:30
# ;;
# (define (casablanca-quote-adate-time symbol)
#   (tm->adate-time-within (localtime (- (current-time) #,(hms->seconds 0 15 0))
# 				    (timezone-casablanca))
# 			 #,(hms->seconds 9 0 0)
# 			 #,(hms->seconds 15 30 0)))


#-----------------------------------------------------------------------------
# download - dividends
#
# This uses the Market Transaction (OST in French) pages like
#
#     http://www.casablanca-bourse.com/fiches/valeurs/MNG/fr/ost.html
#
# The english pages for these are in-progress, apparently, as of Jan 2007,
# so the French pages are used.
#
# The server provides an ETag and Last-Modified which we use to avoid
# getting another copy of data we've already seen and processed.  The
# download is about 11k.

App::Chart::DownloadHandler->new
  (pred         => $pred,
   proc         => \&dividends_download,
   max_symbols  => 1,
   recheck_key  => 'CAS-dividends',
   recheck_days => 7,
   # low priority to get prices first
   priority     => -10);

sub dividends_download {
  my ($symbol_list) = @_;
  my $symbol = $symbol_list->[0];

  my $url = 'http://www.casablanca-bourse.com/fiches/valeurs/'
    . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol))
      . '/fr/ost.html';
  App::Chart::Download::status (__x('Casablanca dividends {symbol}',
                                   symbol => $symbol));
  my $resp = App::Chart::Download->get ($url,
                                       symbol => $symbol,
                                       url_tags_key => 'CAS-dividends');
  my $h = dividends_parse ($symbol, $resp);

  App::Chart::Download::write_daily_group ($h);
}

sub dividends_parse {
  my ($symbol, $resp) = @_;

  my @dividends = ();
  my $h = { source       => __PACKAGE__,
            resp         => $resp,
            url_tags_key => 'CAS-dividends',
            currency     => 'MAD',
            date_format  => 'dmy', # eg. "26.05.00"
            dividends    => \@dividends };
  if (! $resp->is_success) {
    return $h;
  }
  my $content = $resp->decoded_content (raise_error=>1);

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => [ qr/Dividend.*Brut/is,
                  # qr/Num.*Coupon/is,  # coupon number
                  qr/tachement.*la.*Bourse/is ]);
  $te->parse($content);
  if (! $te->tables) {
    die 'Casablanca dividends table not matched';
  }

  foreach my $row ($te->rows) {
    my ($amount, $ex_date) = @$row;

    # "NEANT" (nothing) when current year has no dividends yet
    if ($ex_date =~ /NEANT/i) { next; }

    # amount with comma like "22,00"
    $amount =~ s/,/./g;

    push @dividends, { symbol  => $symbol,
                       amount  => $amount,
                       ex_date => $ex_date,
                     };
  }
  return $h;
}

1;
__END__
