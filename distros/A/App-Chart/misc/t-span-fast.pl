#!/usr/bin/perl -w

# Copyright 2007, 2009, 2010 Kevin Ryde

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
use Set::IntSpan::Fast;

my $a = [ 0, 1, 2, 3, 4 ];
my $b = [ 90, 91, 92, 93, 94 ];
print @$a[1..3],@$b[1..3],"\n";
# print max (undef, 1),"\n";

use List::Util qw(min max);

my $s = Set::IntSpan::Fast->new;
$s->add_range(10, 20);
print $s->as_string,"\n";

my $t = Set::IntSpan::Fast->new;
$t->add_range(5, 25);
print $t->as_string,"\n";

my $d = $t->diff ($s);
print $d->as_string,"\n";
print $d->as_array,"\n";
my $it = $d->iterate_runs;
while (my ($lo, $hi) = $it->()) {
  print "$lo-$hi\n";
}


