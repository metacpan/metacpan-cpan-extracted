#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use App::Chart::Series::Database;

my $symbol = 'BHP.AX';
if (@ARGV) {
  $symbol = shift @ARGV;
}
print "symbol $symbol\n";

my $series = App::Chart::Series::Database->new ($symbol);

my $timebase = $series->timebase;
my $hi = $series->hi;

my $lo_iso = $timebase->to_iso (0);
my $hi_iso = $timebase->to_iso ($hi);
print "data available $lo_iso to $hi_iso\n";

my $start = $hi - 50;
if ($start < 0) { $start = 0; }
my $start_iso = $timebase->to_iso ($start);
print "printing from $start_iso\n";

my $closes = $series->array('closes');
$series->fill ($start, $hi);

foreach my $i ($start .. $hi) {
  my $iso = $timebase->to_iso ($i);
  my $close = $closes->[$i];
  if (defined $close) {
    print "$iso  $close\n";
  }
}

exit 0;
