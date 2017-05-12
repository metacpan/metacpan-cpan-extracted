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
use Set::IntSpan;

my $s = Set::IntSpan->new ("10-20");
print $s->run_list,"\n";
print $s->superset("12-14"),"\n";

my $t = Set::IntSpan->new ("5-25");
print $t->run_list,"\n";
my $d = $t->diff ($s);
print $d->run_list,"\n";
print $d->elements,"\n";
print @{$d->{'edges'}},"\n";


