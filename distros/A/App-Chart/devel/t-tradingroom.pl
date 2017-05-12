#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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

use strict;
use warnings;
use LWP;
use Data::Dumper;
use File::Slurp 'slurp';
use FindBin;
use lib::abs "$FindBin::Bin/lib";
use App::Chart::TradingRoom;

{
  my $req = HTTP::Request->new();
  my $resp = HTTP::Response->new(200,'OK');
  $resp->request ($req);
  my $content = slurp "$ENV{HOME}/chart/samples/tradingroom/pricehistory.ac?section=yearly_price_download&code=NABHA";
  $resp->content($content);

  my $h = App::Chart::TradingRoom::indiv_parse ($resp, 'NABHA.AX');
  # print Dumper ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}
