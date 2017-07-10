#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016, 2017 Kevin Ryde

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
use App::Chart;
use App::Chart::Suffix::MON;

{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp ("$ENV{HOME}/chart/samples/mx/donnees_fin_jour-cgb-2.csv");
  $content = slurp ("$ENV{HOME}/chart/samples/mx/nego_fin_jour_en.php_=o&symbol=&o=&f=CGB&from=2017-07-01&to=2017-07-05&dnld=Download.html");
  $resp->content($content);
  $resp->content_type('text/plain');
  my $h = App::Chart::Suffix::MON::daily_parse ($resp);

  require App::Chart::Download;
  # App::Chart::Download::crunch_h ($h);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp ("$ENV{HOME}/chart/samples/ljse/BTStecajEUR.txt");
  $resp->content($content);
  $resp->content_type('text/plain');
  my $h = App::Chart::Suffix::MON::bts_parse ($resp);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}


exit 0;
