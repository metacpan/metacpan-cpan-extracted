#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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

my $window = Gtk2::Window->new('toplevel');
$window->set_default_size (50,500);
my $ruler = Gtk2::VRuler->new();
$ruler->set_range (0,500,200, -1);
$window->add ($ruler);
$window->show_all;

Gtk2->main();
exit 0;
