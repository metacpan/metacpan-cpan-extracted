# New Zealand Stock Exchange setups.

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package App::Chart::Suffix::NZ;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Database;
use App::Chart::Google;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::DividendsPage;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

# uncomment this to run the ### lines
#use Devel::Comments;


our $timezone_newzealand = App::Chart::TZ->new
  (name     => __('New Zealand'),
   choose   => [ 'Pacific/Auckland' ],
   fallback => 'NST-12');

# http://au.finance.yahoo.com/nzindices
#     ^NZ50
#     ^NZC50
#     ^NZ10G
#     ^NZMGC
#     ^NZGI
#     ^NZSCG
#     ^NZ50G
#     ^NZ30G
my $pred_shares = App::Chart::Sympred::Suffix->new ('.NZ');
my $pred_any = App::Chart::Sympred::Regexp->new (qr/^\^NZ|\.NZ$/);
$timezone_newzealand->setup_for_symbol ($pred_any);

App::Chart::setup_source_help
  ($pred_any, __p('manual-node','New Zealand Stock Exchange'));

# See http://www.nzx.com/markets/key-dates/trading-hours
# pre-open 9am-10am, trading 10am-5pm, adjust 5:30pm, then enquiry
# NZAX shares are only 10am to 4:30pm, but don't worry about that
# (yahoo-quote-lock! newzealand-symbol?
# 		   #,(hms->seconds 9 0 0) #,(hms->seconds 17 30 0))
# Yahoo index values based on last trades, so they should only update
# during trading 10am to 5pm.
# (yahoo-quote-lock! yahoo-index-symbol-newzealand?
# 		   #,(hms->seconds 10 0 0) #,(hms->seconds 17 0 0))

$App::Chart::Google::google_web_pred->add ($pred_shares);


#------------------------------------------------------------------------------
# weblink - NZX company info
#
# Eg. http://www.nzx.com/markets/NZSX/TEL

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('NZX _Company Information'),
   desc => __('Open web browser at the New Zealand Stock Exchange page for this stock'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.nzx.com/markets/NZSX/'
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });


#------------------------------------------------------------------------------
# dividends
#
# This uses the dividend page at
#
use constant DIVIDENDS_URL =>
  'https://www.nzx.com/markets/NZSX/';

App::Chart::DownloadHandler::DividendsPage->new
  (name     => __('NZX dividends'),
   pred     => $pred_shares,
   url      => DIVIDENDS_URL,
   parse    => \&dividends_parse,
   key      => 'NZ-dividends',
   # low priority so prices fetched first
   priority => -10);

sub dividends_parse {
  my ($resp) = @_;

  # note: want wide-chars for HTML::TableExtract parse
  my $body = $resp->decoded_content (raise_error => 1);

  my @dividends = ();
  my $h = { source        => __PACKAGE__,
            resp          => $resp,
            dividends     => \@dividends,
            copyright_key => 'NZ-dividends-copyright',
            copyright     => 'http://www.nzx.com/terms' };

  # Column "Dividend Period" for "interim" or "final" not very interesting.
  # FIXME: what's the "Supp." column?
  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers   => ['Code',
                   'Ex',
                   'Payable',
                   'Amount',
                   'Currency',
                   'Imputation' ]);

  $te->parse($body);
  if (! $te->tables) {
    die "NZX dividend table not matched";
  }

  foreach my $ts ($te->tables) {
    foreach my $row ($ts->rows) {
      my ($symbol, $ex_date, $pay_date, $amount, $currency, $imput)
        = @$row;

      # dummy footnote row
      next if ($symbol =~ /cents per share/);

      push @dividends,
        dividend_parse ($symbol, $ex_date,$pay_date,$amount, $currency,$imput);
    }
  }
  return $h;
}

sub dividend_parse {
  my ($symbol, $ex_date,$pay_date,$amount, $currency,$imput) = @_;

  # leading and trailing whitespace
  $amount = App::Chart::collapse_whitespace ($amount);
  $imput  = App::Chart::collapse_whitespace ($imput);
  $currency = App::Chart::collapse_whitespace ($currency);

  # dates like "16 Aug"
  $ex_date  = dm_str_to_nearest_iso ($ex_date);
  $pay_date = dm_str_to_nearest_iso ($pay_date);

  foreach ($amount, $imput) {
    # eg. "3.900c" with c for cents
    if (s/c$//) {
      $_ = App::Chart::Download::cents_to_dollars ($_);
    }
    # discard trailing zeros when a whole number of cents
    $_ = App::Chart::Download::trim_decimals ($_, 2);
  }

  # foreign like AUD or GBP turned into merely a note
  my $note;
  if ($currency ne 'NZD') {
    if ($imput ne '' && $imput != 0) {
      $note = "$amount + $imput $currency";
    } else {
      $note = "$amount $currency";
    }
    $amount = undef;
    $imput = undef;
  }

  return { symbol     => $symbol,
           ex_date    => $ex_date,
           pay_date   => $pay_date,
           amount     => $amount,
           imputation => $imput,
           note       => $note };
}

sub dm_str_to_nearest_iso {
  my ($str) = @_;
  require Date::Parse;
  my ($sec, $min, $hour, $mday, $mon, $year) = Date::Parse::strptime($str);
  if ($year) {
    $year += 1900;
  } else {
    $year = App::Chart::Download::month_to_nearest_year ($mon+1);
  }
  return App::Chart::ymd_to_iso ($year, $mon+1, $mday);
}

1;
__END__
