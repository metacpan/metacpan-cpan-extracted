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


use 5.008;
use strict;
use warnings;
use Test::More tests => 3;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::HAxis;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  {
    my $haxis = App::Chart::Gtk2::HAxis->new;
    require Scalar::Util;
    Scalar::Util::weaken ($haxis);
    is ($haxis, undef,
        'garbage collect when weakened');
  }

  {
    my $adj = Gtk2::Adjustment->new  (0, 0, 1, 1, 1, 1);
    my $haxis = App::Chart::Gtk2::HAxis->new (adjustment => $adj);
    Scalar::Util::weaken ($haxis);
    is ($haxis, undef,
        'garbage collect when weakened -- with adj');
  }

  {
    my $adj1 = Gtk2::Adjustment->new  (0, 0, 1, 1, 1, 1);
    my $haxis = App::Chart::Gtk2::HAxis->new;
    my $adj2 = Gtk2::Adjustment->new  (0, 0, 1, 1, 1, 1);
    $haxis->set (adjustment => $adj2);
    Scalar::Util::weaken ($adj1);
    is ($adj1, undef,
        'previous adjustment unreferenced');
  }
}

exit 0;

