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

use App::Chart::Series;
use App::Chart::Series::Database;
use Data::Dumper;

my $series = App::Chart::Series::Database->new ('TEL.NZ');
print "db to ",$series->hi,"\n";

print keys %{$series->{'arrays'}},"\n";
my $sma = $series->OBV(10);
print Dumper ($sma);

my $t = $sma->hi;
print "indic to $t\n";

$sma->fill ($t, $t);
my $a = $sma->values_array;
print $a->[$t],"\n";
exit 0;
