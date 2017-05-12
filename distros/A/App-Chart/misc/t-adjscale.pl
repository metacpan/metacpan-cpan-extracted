#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use POSIX qw(setlocale LC_ALL strftime);
use App::Chart::Gtk2::AdjScale;
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_size_request (300, 200);
$toplevel->realize;

my $adj = App::Chart::Gtk2::AdjScale->new (widget => $toplevel);
$adj->set_page_range (0, 100_000);
print Dumper ($adj);

print "height ",$toplevel->allocation->height,"\n";
print $adj->value_to_pixel (0), "\n";
print $adj->value_to_pixel (100_000), "\n";

exit 0;
