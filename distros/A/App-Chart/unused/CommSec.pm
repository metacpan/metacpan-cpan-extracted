
                    # { key => 'commsec-enable',
                    #   name => __('Enable CommSec (must be a client)'),
                    #   type => 'boolean' },

# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

package App::Chart::CommSec;
use 5.008;
use strict;
use warnings;
use Carp;
use Date::Calc;
use File::Basename;
use List::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadCost;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::Timebase::Months;
use App::Chart::TZ;


my $pred = App::Chart::Sympred::Proc->new (\&is_commsec_symbol);
sub is_commsec_symbol {
  my ($symbol) = @_;
  if (! is_enabled()) { return 0; }
  no warnings 'once';
  require App::Chart::Suffix::AX;
  return $App::Chart::Suffix::AX::pred_shares->match ($symbol);
}
sub is_enabled {
  return App::Chart::Database->preference_get ('commsec-enable');
}
# use App::Chart::Memoize::ConstSecond 'is_enabled';


#-----------------------------------------------------------------------------
# download
#
# The download chooses between
#    - commsec whole-day update files
#    - commsec individual update files
#
# To update many ASX shares the whole-day files are best, or for just a few
# then the individual files are best.  A mixture is used too, if there's a
# few symbols that are quite a bit behind then they'll be done
# individually, and the balance with whole-day.
#
# The main problem with the whole-day file is how many entries it has,
# about 4500 as of Jan 2007.  There's about 1600 companies (a lot of them
# small caps), the rest is warrants on the majors, and a few prefs or bonds
# on various.

App::Chart::DownloadHandler->new
  (name            => __('CommSec'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   proc            => \&download,
   priority        => 10);

# today's data available after 10:30pm weekdays, Sydney time
sub available_tdate {
  App::Chart::Download::tdate_today_after
      (22,30, App::Chart::TZ->sydney);
}

use constant { INDIV_PERMONTH_COST_KEY => 'commsec-indiv',
               INDIV_PERMONTH_COST_DEFAULT => 1300,
               WHOLEDAY_COST_KEY => 'commsec-wholeday' };

sub download {
  my ($symbol_list) = @_;
  App::Chart::Download::status (__('CommSec strategy'));

  my $avail = available_tdate();

  require App::Chart::DownloadCost;
  my ($whole_tdate, @indiv_list) = App::Chart::DownloadCost::by_day_or_by_symbol
    (available_tdate  => $avail,
     symbol_list      => $symbol_list,
     indiv_cost_proc  => \&indiv_cost_proc,
     whole_cost_key     => WHOLEDAY_COST_KEY,
     whole_cost_default => 259867); # May 2008

  App::Chart::Download::verbose_message
      (__x('CommSec whole days from {date} after indiv {symbols}',
           date => App::Chart::tdate_to_iso($whole_tdate),
           symbols => join(' ', @indiv_list)));

  foreach my $symbol (@indiv_list) { indiv_download ($symbol); }
  wholeday_download ($whole_tdate, $avail);
}

#------------------------------------------------------------------------------
# download - by each symbol
#
# This uses the download of all data for a symbol like
#

my @indiv_months_list = ([1,   '1mo' ],
                         [2,   '2mo' ],
                         [3,   '3mo' ],
                         [6,   '6mo' ],
                         [12,  '1yr' ],
                         [24,  '2yr' ],
                         [36,  '3yr' ],
                         [48,  '4yr' ],
                         [60,  '5yr' ],
                         [120, '10yr']);

sub indiv_download {
  my @symbol_list = @_;

  foreach my $symbol (@symbol_list) {
    my $tdate = App::Chart::Download::start_tdate_for_update ($symbol);
    my $months = indiv_tdate_to_months ($tdate);
    my $elem
      = (List::Util::first {$_->[0] >= $months } @indiv_months_list)
        || $indiv_months_list[-1];
    my $period_str = $elem->[1];

    my $url
      = 'http://charts.commsec.com.au/HistoryData/HistoryData.dll/GetData'
        . '?Symbol='
          . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol))
            . '&TimePeriod=' . $period_str
              . '&.csv';

    App::Chart::Download::status (__x('CommSec {symbol} {period}',
                                     symbol => $symbol,
                                     period => $period_str));

    my $resp = App::Chart::Download->get($url);
    my $h = indiv_parse ($resp, $months);
    if ($h) {
      $h->{'last_download'} = 1;
      App::Chart::Download::write_daily_group ($h);
    }
  }
}

# return number of months needed to cover back to TDATE
sub indiv_tdate_to_months {
  my ($tdate) = @_;
  $tdate -= 5;  # bit of leeway
  my ($now_year, $now_month, $now_day)
    = App::Chart::TZ->sydney->ymd;
  my ($td_year, $td_month, $td_day) = App::Chart::tdate_to_ymd ($tdate);

  my $now_mdate
    = App::Chart::Timebase::Months::ymd_to_mdate ($now_year, $now_month, 1);
  my $td_mdate
    = App::Chart::Timebase::Months::ymd_to_mdate ($td_year, $td_month, 1);

  return $now_mdate - $td_mdate + ($now_day >= $td_day ? 1 : 0);
}

sub indiv_cost_proc {
  my ($tdate) = @_;
  my $months = indiv_tdate_to_months ($tdate);
  return $months
    * App::Chart::DownloadCost::cost_get (INDIV_PERMONTH_COST_KEY,
                                         INDIV_PERMONTH_COST_DEFAULT);
}

sub indiv_parse {
  my ($resp, $months) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            currency        => 'AUD',
            suffix          => '.AX',
            prefer_decimals => 2,
            date_format     => 'dmy',
            resp            => $resp,
            data            => \@data };

  my $body = $resp->decoded_content(raise_error=>1);
  if ($body =~ /server error/i) {
    # an unknown symbol
    return $h;
  }

  $h->{'cost_key'} = INDIV_PERMONTH_COST_KEY;
  $h->{'cost_value'} = int (length($body) / $months);

  # Sample line
  #
  #     AEZ,"01 Jun 2007",1.35,1.37,1.305,1.325,4008329\r\n
  #
  # trailing zeros are omitted, like 4.30 or 95.00 in
  # 
  #     ETR,"29 May 2007",4.26,4.3,4.25,4.3,50942\r\n
  #     NABHA,"27 Dec 2000",94.41,95,94.41,94.99,3495\r\n
  #
  foreach my $line (App::Chart::Download::split_lines($body)) {
    my ($symbol, $date, $open, $high, $low, $close, $volume)
      = split (/,/, $line);

    $symbol .= '.AX';
    $open  = pad_decimals ($open, 2);
    $high  = pad_decimals ($high, 2);
    $low   = pad_decimals ($low, 2);
    $close = pad_decimals ($close, 2);

    push @data, { symbol => $symbol,
                  date   => $date,
                  open   => $open,
                  high   => $high,
                  low    => $low,
                  close  => $close,
                  volume => $volume };
  }
  return $h;
}

sub pad_decimals {
  my ($str, $want) = @_;
  if ($str =~ /\.([0-9]*)$/) {
    my $got = length ($1);
    if ($got < $want) {
      $str .= '0' x ($want - $got);
    }
  } else {
    # no decimal point at all
    $str .= '.' . ('0' x $want);
  }
  return $str;
}

#-----------------------------------------------------------------------------
# download - by whole day files
#
# Commsec offers the following formats,
#
#     metastock - prices in dollars, date yymmdd
#     metastock - prices in dollars, date yymmdd, volume in 100s
#     ezychart  - prices in cents, date yymmdd
#     insight   - prices in cents, date mm/dd/yy, space separated
#     stockeasy - prices in dollars, date yyyymmdd
#
# Ezychart is used because it's the most compact -- there's no decimal
# points in most prices, and no century on the date.
#
# The web page says only the past 20 days are available and that's all the
# little menu presents, but the server actually goes back beyond that,
# apparently unlimited.

# return a url string
sub wholeday_url {
  my ($tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
   return sprintf 'http://charts.commsec.com.au/HistoryData/HistoryData.dll/EzyChart-%d%02d%02d?DownloadDate=%d%02d%02d&DownloadFormat=EzyChart&.txt',
     $year, $month, $day,
     $year, $month, $day;
}

sub wholeday_download {
  my ($start_tdate, $avail_tdate) = @_;
  foreach my $tdate ($start_tdate .. $avail_tdate) {
    App::Chart::Download::status
        (__x('CommSec data {date}',
             date => App::Chart::Download::tdate_range_string ($tdate)));

    my $url = wholeday_url($tdate);
    my $resp = App::Chart::Download->get ($url);

    # when public holiday, date too old, etc, still get a successful
    # download, with an error message in the body
    my $h = ezychart_parse ($resp);
    App::Chart::Download::write_daily_group ($h);
  }
}

sub ezychart_parse {
  my ($resp) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            currency        => 'AUD',
            prefer_decimals => 2,
            date_format     => 'ymd',
            resp            => $resp,
            data            => \@data,
            cost_key        => WHOLEDAY_COST_KEY };

  my $body = $resp->decoded_content(raise_error=>1);
  if ($body =~ /server error/i) {
    # an unknown symbol
    return $h;
  }

  # Sample line, 5 Sep 2008
  # BHP,080905,3640,3720,3630,3700,14390282
  #
  foreach my $line (App::Chart::Download::split_lines($body)) {
    my ($symbol, $date, $open, $high, $low, $close, $volume)
      = split (/,/, $line);

    $open  = App::Chart::Download::cents_to_dollars ($open);
    $high  = App::Chart::Download::cents_to_dollars ($high);
    $low   = App::Chart::Download::cents_to_dollars ($low);
    $close = App::Chart::Download::cents_to_dollars ($close);

    push @data, { symbol => "$symbol.AX",
                  date   => $date,
                  open   => $open,
                  high   => $high,
                  low    => $low,
                  close  => $close,
                  volume => $volume };
  }
  return $h;
}

1;
__END__
