# Copyright 2007, 2008, 2009, 2010, 2011, 2015, 2016, 2017 Kevin Ryde

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


#------------------------------------------------------------------------------
# Yahoo

# Previous historical daily data:
#
#     http://finance.yahoo.com/q/hp?s=AMP.AX
#
# which had a CSV link like
#
#     http://ichart.finance.yahoo.com/table.csv?s=NABHA.AX&d=5&e=26&f=2015&g=d&a=3&b=26&c=2015&ignore=.csv
#
# national sites like au.finance.yahoo.com with a redirector like
#
#     http://au.rd.yahoo.com/finance/quotes/internal/historical/download/*http://ichart.finance.yahoo.com/table.csv?s=AMP.AX&d=10&e=26&f=2007&g=d&a=0&b=4&c=2000&ignore=.csv
#
# If there's no data at all in the requested range the response is a 404
# (with various bits of HTML in the body).

sub daily_url {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;
  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);
  return 'http://ichart.finance.yahoo.com/table.csv?'
    . 's=' . URI::Escape::uri_escape ($symbol)
    . '&d=' . ($hi_month - 1)
    . '&e=' . $hi_day
    . '&f=' . $hi_year
    . '&g=d'
    . '&a=' . ($lo_month - 1)
    . '&b=' . $lo_day
    . '&c=' . $lo_year
    . '&ignore=.csv';
}


#-----------------------------------------------------------------------------
# Yahoo
#
# intraday images
#
# Images are fetched from the yahoo charts section, gifs like
#
#     http://ichart.finance.yahoo.com/z?s=%5EGSPC&t=1d&q=l&l=off&z=l&p=s
#
# or the link from au.finance.yahoo.com is say
#
#     http://cchart.yahoo.com/z?s=CML.AX&t=5d&l=off&z=l&q=l&i=au
#
# Those two hostnames resolve to the same IP, don't know which one is
# really meant to be used.
#
# The parts are
#
#     s=SYMBOL
#     t=1d   1 day
#       5d   5 days
#     q=l    line
#       b    bar
#       c    candle
#     l=on   logarithmic
#       off  linear
#     z=m    medium size
#       l    large size
#     a=  comma separated list of indicators
#       v    volume
#       vm   volume moving average
#       r14  RSI
#
# Unfortunately there's no last-modified or etag to indicate when the image
# has nothing new yet, or is unchanged outside trading hours.

# the futures charts from yahoo don't look too good, eg OU07.CBT, so stay
# with barchart for them
sub is_intraday_symbol {
  my ($symbol) = @_;
  my $suffix = App::Chart::symbol_suffix ($symbol);
  return (length($suffix) <= 3
          && $latest_pred->match($symbol));
}
my $intraday_pred = App::Chart::Sympred::Proc->new (\&is_intraday_symbol);

foreach my $n (1, 5) {
  App::Chart::IntradayHandler->new
      (pred => $intraday_pred,
       proc => \&intraday_url,
       mode => "${n}d",
       name => __nx('_{n} Day',
                    '_{n} Days',
                    $n,
                    n => $n));
}

sub intraday_url {
  my ($self, $symbol, $mode) = @_;
  App::Chart::Download::status (__x('Yahoo intraday {symbol} {mode}',
                                    symbol => $symbol,
                                    mode => $mode));
  return 'http://ichart.finance.yahoo.com/z?s='
    . URI::Escape::uri_escape ($symbol)
      . '&t=' . $mode
        . '&l=off&z=m&q=l&a=v';
}



#-----------------------------------------------------------------------------
