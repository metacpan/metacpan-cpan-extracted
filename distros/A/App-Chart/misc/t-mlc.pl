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
use Data::Dumper;
use File::Slurp;
use HTTP::Response;
use App::Chart::Suffix::MLC;

{
  my $resp = HTTP::Response->new();
  my $content = File::Slurp::slurp ($ENV{'HOME'}.'/chart/samples/mlc/mlc.data');
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::MLC::parse ($resp);
  print Dumper ($h);
  App::Chart::Download::write_latest_group ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}
