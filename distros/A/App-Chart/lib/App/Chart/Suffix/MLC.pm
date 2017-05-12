# MLC data downloading.

# Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Suffix::MLC;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::IndivChunks;
use App::Chart::Latest;
use App::Chart::Sympred;
use App::Chart::TZ;

my $pred = App::Chart::Sympred::Suffix->new ('.MLC');

# not sure exactly where MLC operates out of, but Sydney is close enough
App::Chart::TZ->sydney->setup_for_symbol ($pred);

App::Chart::setup_source_help
  ($pred, __p('manual-node','MLC Funds'));

# The home page has a link to fund descriptions, unfortunately it's in
# flash format.


#-----------------------------------------------------------------------------
# download
#
# This uses the unit prices under
#
#     https://www.mlc.com.au/masterkeyWeb/execute/FramesetUnitPrices
#
# Filling in the boxes ends up with a url like the following, with full
# fund and product name, and a requested date range (dd/mm/yyyy).
#
#     https://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=MasterKey%20Superannuation%20%28Gold%20Star%29&fund=Property%20Securities%20Fund&begindate=19/07/2003&enddate=19/07/2004&
#
# Old data has prices for weekends too, but the same as Friday.
#

App::Chart::DownloadHandler::IndivChunks->new
  (name            => __('MLC'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   url_func        => \&url_func,
   parse           => \&parse,

   # If you fill in the web page boxes asking for more than 1 year it
   # explains you can only get 1 year at a time (you get 1 year from the
   # given start date).
   chunk_size      => 250);

# Return the expected available tdate for data.
#
# This is only based on observation, in the morning it seems to be not the
# previous weekday but the one before that, and Thursday on a weekend.
# Don't know what time of day it ticks over, assume midnight for now.
#
sub available_tdate {
  return App::Chart::Download::tdate_today_after
    (23,59, App::Chart::TZ->sydney)
      - 1;
}

# Sample url:
# https://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=MasterKey%20Allocated%20Pension%20%28Five%20Star%29&fund=MLC%20MasterKey%20Horizon%201%20-%20Bond%20Portfolio&begindate=07/01/2007&enddate=07/01/2008&
#
# In the past it was plain http:
# http://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=MasterKey%20Superannuation%20%28Gold%20Star%29&fund=Property%20Securities%20Fund&begindate=19/07/2003&enddate=19/07/2004&
#
sub url_func {
  my ($symbol, $lo, $hi) = @_;
  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi);
  my ($fund, $product) = split /,/, App::Chart::symbol_sans_suffix ($symbol);
  return sprintf ('https://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=%s&fund=%s&begindate=%02d/%02d/%04d&enddate=%02d/%02d/%04d&',
                  URI::Escape::uri_escape ($product),
                  URI::Escape::uri_escape ($fund),
                  $lo_day, $lo_month, $lo_year,
                  $hi_day, $hi_month, $hi_year);
}

# Lines like:
# historicalProduct1funds[1]="MLC Property Securities Fund,MasterKey Superannuation (Gold Star),29 March 2007,64.71567,0.00000";
#
sub parse {
  my ($symbol, $resp) = @_;
  my $content = $resp->decoded_content(raise_error=>1);

  my @data = ();
  my $h = { source   => __PACKAGE__,
            resp     => $resp,
            currency => 'AUD',
            data     => \@data };

  while ($content =~ /^historicalProduct1funds.*=\"(.*)\"/mg) {
    my ($fund, $product, $date, $price) = split /,/, $1;

    # skip historicalProduct1funds[0]="All Funds" bit
    if (! $product) { next; }

    my ($year, $month, $day) = Date::Calc::Decode_Date_EU ($date);
    # skip weekends in some old data
    next if (ymd_is_weekend ($year, $month, $day));
    $date = App::Chart::ymd_to_iso ($year, $month, $day);

    push @data, { symbol => $fund . ',' . $product . '.MLC',
                  date   => $date,
                  close  => $price };
  }
  return $h;
}

sub validate_symbol {
  my ($symbol) = @_;
  if ($symbol !~ /,/) {
    print __x("MLC: invalid symbol, should be \"Fund,Product.MLC\": {symbol}\n",
              symbol => $symbol);
    return 0;
  }
  return 1;
}


#------------------------------------------------------------------------------
# latest
#
# The approach here is to download the latest price the same as for the
# database above, getting the latest and second latest, so as to calculate a
# "change", and back a few extra days to allow for public holidays.
#
# There's a single download of latest prices for all funds and products.  If
# $symbol_list was big then it might be worth doing that instead of
# individual downloads, but not sure if a set of immediately preceding
# prices would be available to make the "change" amount.  In any case for
# now it's probably unlikely there'll be many funds in the watchlist that
# are not in the database.
#

App::Chart::LatestHandler->new
  (pred => $pred,
   proc => \&latest,
   max_symbols => 1,
   available_tdate => \&available_tdate);

sub latest {
  my ($symbol_list) = @_;
  my $symbol = $symbol_list->[0];
  if (! validate_symbol ($symbol)) { return; }
  my $avail_tdate = available_tdate();
  my $url = url_func ($symbol, $avail_tdate-3, $avail_tdate+1);
  my $resp = App::Chart::Download->get ($url);
  App::Chart::Download::write_latest_group (parse ($symbol, $resp));
}


#-----------------------------------------------------------------------------
# generic helpers

sub ymd_is_weekend {
  my ($year, $month, $day) = @_;
  return (Date::Calc::Day_of_Week ($year, $month, $day) >= 6); # 6 or 7
}


1;
__END__
