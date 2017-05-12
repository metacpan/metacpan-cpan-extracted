#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

# use strict;
# use warnings;
use App::Chart::Tie::Hash::Union;

print $],"\n";

my %x = (a => 1, b => 2);
my %y = (c => 3);

my %h;
tie %h, 'App::Chart::Tie::Hash::Union', \%x, \%y;

print $h{'a'},"\n";
print $h{'b'},"\n";
print $h{'c'},"\n";
print keys %h, "\n";
print scalar(%x), "\n";
print scalar(%y), "\n";
print scalar(%h), "\n";
print scalar(%{tied(%h)}), "\n";

print "extend\n";
keys(%h) = 1000;
print scalar(%x), "\n";
print scalar(%y), "\n";
print scalar(%h), "\n";
print scalar(%{tied(%h)}), "\n";


# wantarray
