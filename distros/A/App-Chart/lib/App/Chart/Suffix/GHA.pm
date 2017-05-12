# gone away ?



# Ghana Stock Exchange setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2014, 2016 Kevin Ryde

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


# company profile
# http://www.gse.com.gh/listedcomps.php?cmd=cmppro&scd=CAL
#

package App::Chart::Suffix::GHA;
use 5.010;
use strict;
use warnings;
use List::Util qw(min max);
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::IndivInfo;
use App::Chart::Latest;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


# FIXME: Accra is GMT with no daylight savings, so Time::TZ->tz_known()
# can't tell if it's ok
my $timezone_accra = App::Chart::TZ->new
  (name => __('Accra'),
   tz   => 'Africa/Accra');

my $pred = App::Chart::Sympred::Suffix->new ('.GHA');
$timezone_accra->setup_for_symbol ($pred);

# App::Chart::setup_source_help
#   ($pred, __p('manual-node','Ghana Stock Exchange'));


#------------------------------------------------------------------------------
# weblink - company info
#
# Eg. http://www.gse.com.gh/index1.php?linkid=46&scd=CAL

App::Chart::Weblink->new
  (pred => $pred,
   name => __('GSE _Company Information'),
   desc => __('Open web browser at the Ghana Stock Exchange information page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.gse.com.gh/index1.php?linkid=46&scd='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });


#-----------------------------------------------------------------------------
# daily data page
#
# This uses the daily data page,
#
use constant GSE_DAILY_URL =>
  'http://www.gse.com.gh/index1.php?linkid=5&sublinkid=12';

App::Chart::DownloadHandler->new
  (name   => __('GSE'),
   pred   => $pred,
   proc   => \&daily_download,
   available_date_time => \&daily_available_date_time);

# Return date and time strings for the available daily report.
#
# Trading is from 10am to about midday, not sure when the new day's data
# will appear, have seen it still not available after midnight on the
# trading day, so let's try from 9am the following day.
# 
sub daily_available_date_time {
  return (App::Chart::Download::weekday_date_after_time
          (9,0, $timezone_accra, -1),
          '09:00:00');
}

sub daily_download {
  my ($symbol_list) = @_;
  App::Chart::Download::status (__('GSE latest daily data'));
  my $newest_resp = App::Chart::Download->get (GSE_DAILY_URL);
  my $newest_h = daily_parse ($newest_resp);
  App::Chart::Download::write_latest_group ($newest_h);

  my $start_tdate = App::Chart::Download::start_tdate_for_update(@$symbol_list);
  my $newest_tdate = App::Chart::Download::iso_to_tdate_floor
    ($newest_h->{'data'}->[0]->{'date'});
  if ($newest_tdate < $start_tdate) { return; }

  foreach my $session (daily_sessions ($newest_resp)) {
    my ($code, $tdate) = @$session;
    if ($tdate < $start_tdate) { next; }

    App::Chart::Download::status
        (__x('GSE data {date}',
             date => App::Chart::Download::tdate_range_string ($tdate)));
    my $resp = App::Chart::Download->get (GSE_DAILY_URL . "?session=$code");

    my $h = daily_parse ($resp);
    App::Chart::Download::write_daily_group ($h);
  }
  App::Chart::Download::write_daily_group ($newest_h);
}

# return values ([$code,$tdate],...) which are the available sessions, by
# session code and tdate, sorted from oldest to newest tdate
sub daily_sessions {
  my ($resp) = @_;
  my $content = $resp->decoded_content(raise_error=>1);
  my @ret = ();
  # Eg. <option   value="2425"> 18/01/2007 </option>
  while ($content =~ m{<option +value=\"([0-9]+)\"> *([0-9]+/[0-9]+/[0-9][0-9][0-9][0-9]) *</option>}g) {
    my $code = $1;
    my $tdate = App::Chart::ymd_to_tdate_floor
      (Date::Calc::Decode_Date_EU ($2)); # d/m/y
    push @ret, [$code, $tdate];
  }
  return sort {$a->[1] <=> $b->[1]} @ret;
}

sub daily_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content(raise_error=>1);

  my @data = ();
  my $h = { source      => __PACKAGE__,
            url         => GSE_DAILY_URL,
            resp        => $resp,
            currency    => 'GHC',
            date_format => 'dmy',
            data        => \@data };

  # Eg. "24/04/2006\n\t\t</font>&nbsp;Trading Results"
  $content =~ m{([0-9]+/[0-9]+/[0-9][0-9][0-9][0-9])([ \t\n]*(<[^>]*>|&nbsp;))*[ \t\n]*Trading Results}
    or die "GSE: daily page date not found\n";
  my $date = $1;

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['', # no heading above symbols
                 'ISIN', 'Bid', 'Offer', 'Opening', 'Closing', 'Change',
                 'Traded' ]);
  $te->parse($content);
  if (! $te->tables) { die "GSE: daily page price table not found\n"; }

  foreach my $row ($te->rows) {
    my ($symbol, $isin, $bid, $offer, $open, $close, $change, $volume) = @$row;
    $symbol =~ s/^ +//;  # lose leading space

    # sub-heading
    if ($symbol =~ /First List/) { next; }

    # 18jan07 had an empty row, delete that based on empty symbol field
    if ($symbol eq '') { next; }

    push @data, { symbol    => $symbol . '.GHA',
                  isin      => $isin,
                  date      => $date,
                  bid       => $bid,
                  offer     => $offer,
                  open      => $open,
                  close     => $close,
                  change    => $change,
                  volume    => $volume,
                };
  }
  return $h;
}


#-----------------------------------------------------------------------------
# latest
#
# This uses the daily data page above.

App::Chart::LatestHandler->new
  (pred => $pred,
   proc => \&latest_download,
   available_date_time => \&daily_available_date_time);

sub latest_download {
  my ($symbol_list) = @_;

  App::Chart::Download::status (__('GSE latest daily data'));
  my $resp = App::Chart::Download->get (GSE_DAILY_URL);
  App::Chart::Download::write_latest_group (daily_parse ($resp));

  # and update database at the same time
  # (ghana-process-download '() body)))

}


# #-----------------------------------------------------------------------------
# # names
# #
# # This uses the info pages like
# #
# #     http://www.gse.com.gh/marketstat/officiallist_details.asp?Symbol=ABL
# #
# # though they aren't available for all shares.
# #
# 
# App::Chart::DownloadHandler::IndivInfo->new
#   (name     => __('GSE names'),
#    key      => 'GHA-names',
#    pred     => $pred,
#    url_func => \&name_url,
#    parse    => \&name_parse,
#    recheck_days => 10);
# 
# sub name_url {
#   my ($symbol) = @_;
#   return 'http://www.gse.com.gh/marketstat/officiallist_details.asp?Symbol='
#     . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
# }
# 
# sub name_parse {
#   my ($symbol, $resp) = @_;
# 
#   # eg. "    <td><strong> <span class="just">2241 <strong>&nbsp;Trading Session </strong></span>for:<font color="#D98713"> Accra Brewery Company Ltd.</font></strong></td>"
# 
#   my $body = $resp->decoded_content (raise_error => 1);
#   $body =~ s/<[^>]*>//g;  # no html
#   $body =~ /Trading Session.*for:([^\n]*)/
#     or die "GSE: company name not found for '$symbol'";
#   my $name = App::Chart::collapse_whitespace ($1);
#   return { name => $name };
# }

1;
__END__








# @c ---------------------------------------------------------------------------
# @node Ghana Stock Exchange, MLC Funds, Finance Quote, Data Sources
# @section Ghana Stock Exchange
# @cindex Ghana Stock Exchange
# @cindex GSE
# 
# @uref{http://www.gse.com.gh}
# 
# GSE provides
# 
# @itemize
# @item
# Daily data for the past 4 weeks.
# @end itemize
# 
# @cindex @code{.GHA}
# In Chart symbols are the exchange code and a @samp{.GHA} suffix, for example
# @samp{CAL.GHA} for CAL Bank Limited.
# 
# @c FIXME: Gone away as of June 2009
# @c
# @c   Symbols can be found on the daily page,
# @c @c SYMBOL: CAL.GHA
# @c 
# @c @quotation
# @c @uref{http://www.gse.com.gh/marketstat/equitiesdef.asp}
# @c @end quotation


