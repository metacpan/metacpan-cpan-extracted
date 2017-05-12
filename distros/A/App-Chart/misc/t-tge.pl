#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016 Kevin Ryde

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
use App::Chart::Suffix::TGE;

use LWP;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Slurp 'slurp';
use App::Chart;
use Date::Calc;

{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp(<~/chart/samples/tge/co01.csv>);
  $resp->content($content);
  $resp->content_type('text/plain');
  my $h = App::Chart::Suffix::TGE::csv_parse ($content);

  print Dumper ($h);
  require App::Chart::Download;
  App::Chart::Download::crunch_h ($h);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}

{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp(<~/chart/samples/tge/co01040603050602.zip>);
  $resp->content($content);
  $resp->content_type('application/zip');
  my $h = App::Chart::Suffix::TGE::zip_parse ($resp);

  print Dumper ($h);
  require App::Chart::Download;
  App::Chart::Download::crunch_h ($h);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}

{
  require App::Chart::Download;
  my ($year, $month, $day) = App::Chart::Download::Decode_Date_YMD ('20080131');
  print "$year, $month, $day\n";
  exit 0;
}
