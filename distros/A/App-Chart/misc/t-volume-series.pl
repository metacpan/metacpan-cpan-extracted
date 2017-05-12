#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use List::Util qw(min max);
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::Series::Database;
use App::Chart::Series::Volume;

{
  my $series = App::Chart::Series::Database->new('BHP.AX');
  print Dumper (\$series);
  print "hi ", $series->hi, "\n";
  print "decimals ", $series->decimals, "\n";

  print "volume\n";
  my $volume = App::Chart::Series::Volume->derive($series, 'App::Chart::Timebase::Weeks');
  print "hi ", $volume->hi, "\n";
  print "decimals ", $volume->decimals, "\n";

  my @initial_range = $volume->initial_range;
  print Dumper (\@initial_range);
  exit 0;
}
