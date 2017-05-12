# Copyright 2015, 2016 Kevin Ryde

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

package App::Chart::TradingRoom;
use 5.008;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


#------------------------------------------------------------------------------
# weblink - Trading Room summary page
#
# Summary page with delayed quote, some ASX announcements.
#
#     http://www.tradingroom.com.au
/apps/qt/quote.ac?sy=tpl&type=delayedquote&code=NABHA
# 
# or cf detailed quote page which has bits of market cap, 52-weeks etc
#
#     http://www.tradingroom.com.au/apps/qt/quote.ac?section=quotedetail&sy=tpl&type=delayedquote&code=WBCPE
#
# The intraday chart is some stupid script so can't easily get an image from
# it.

App::Chart::Weblink->new
  (pred => App::Chart::Sympred::Suffix->new('.AX'),
   name => __('Tradig Room Summary'),
   desc => __('Open web browser at the Trading Room summary page for these shares'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.tradingroom.com.au/apps/qt/quote.ac?sy=tpl&type=delayedquote&code='
       . URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
   });


#-----------------------------------------------------------------------------
# download - prefs
#
# For ordinary NAB.AX etc prefer Yahoo which takes a date range and goes
# back further than a year.  But as of June 2015 it doesn't have historical
# data for preference shares like NABHA.AX (though it does have quotes).
# Use Trading Room 1-year csv for ASX prefs.  Its csv is about 13kbytes for
# the full year, with no compression offered apparently.
#
App::Chart::DownloadHandler->new
  (name            => __('TradingRoom'),
   pred            => App::Chart::Sympred::Regexp->new (qr/^.{4,}\.AX$/),
   available_tdate => \&available_tdate,
   proc            => \&download,
   priority        => 10);

# today's data available ...
sub available_tdate {
  App::Chart::Download::tdate_today_after
      (23,59, App::Chart::TZ->sydney);
}

sub download {
  my ($symbol_list) = @_;
  foreach my $symbol (@$symbol_list) {
    indiv_download ($symbol);
  }
}

#------------------------------------------------------------------------------
# download - by each symbol
#
# This uses the CSV 1-year download.  Eg. symbol like NABHA
#
#     http://www.tradingroom.com.au/apps/qt/csv/pricehistory.ac?section=yearly_price_download&code=NABHA

sub indiv_download {
  my @symbol_list = @_;

  foreach my $symbol (@symbol_list) {
    my $url = 'http://www.tradingroom.com.au/apps/qt/csv/pricehistory.ac?section=yearly_price_download&code='
      . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix($symbol));

    App::Chart::Download::status (__x('TradingRoom {symbol} 1-year',
                                      symbol => $symbol));

    my $resp = App::Chart::Download->get($url);
    my $h = indiv_parse ($resp, $symbol);
    if ($h) {
      $h->{'last_download'} = 1;
      App::Chart::Download::write_daily_group ($h);
    }
  }
}

# $symbol like "NABHA.AX"
sub indiv_parse {
  my ($resp, $symbol) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            currency        => 'AUD',
            suffix          => '.AX',
            prefer_decimals => 2,
            date_format     => 'dmy',
            resp            => $resp,
            data            => \@data };

  my $body = $resp->decoded_content(raise_error=>1);

  # Like
  #
  #     Date,Open,High,Low,Close,Volume,Cumulative Dilution Factor
  #     25-Jun-2015,94.6100,94.9000,94.5900,94.8000,7581,1
  #
  # 4 decimals so can be fractions of a cent.
  # Unknown symbol is heading but no data lines.
  # 
  my @lines = App::Chart::Download::split_lines($body);
  {
    my $heading = shift @lines;
    $heading =~ /^Date,Open,High,Low,Close,Volume(,|$)/i
      or die 'TradingRoom: unrecognised heading line: ',$heading;
  }
    
  foreach my $line (@lines) {
    my ($date, $open, $high, $low, $close, $volume)
      = split (/,/, $line);

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

1;
__END__







# use App::Chart::TradingRoom;

# @c ---------------------------------------------------------------------------
# @node Trading Room, Yahoo Finance, Thrift Savings Plan, Data Sources
# @section Trading Room
# @cindex @code{tradingroom.com.au}
# 
# @uref{tradingroom.com.au}
# 
# @cindex Australian Stock Exchange
# @cindex ASX
# Trading Room is used for the following Australian Stock Exchange data,
# 
# @itemize
# @item
# Preference shares daily data for past 1 year.
# @end itemize
# 
# Each day's data is available some time overnight of the same day.  Chart will
# attempt from midnight onwards (Sydney time).
# 
# The site terms are one copy for personal use and not for republication (as of
# June 2015).
# 
# @quotation
# @uref{http://www.fairfax.com.au/conditions}
# @end quotation
# 
# Yahoo is used for ASX ordinary shares since it goes further back and takes a
# date range for smaller updates, but Yahoo doesn't have historical data for
# preference shares, hybrids, and notes such as @code{NABHA.AX}.
# @c SYMBOL: NABHA.AX


