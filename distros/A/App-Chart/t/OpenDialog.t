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

use Test::More tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::OpenDialog;
require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 2;

  {
    my $open = App::Chart::Gtk2::OpenDialog->new;
    $open->destroy;
    MyTestHelpers::main_iterations();
    require Scalar::Util;
    Scalar::Util::weaken ($open);
    is ($open, undef,
        'garbage collect after destroy');
  }

  {
    my $open = App::Chart::Gtk2::OpenDialog->new;
    $open->show;
    $open->destroy;
    MyTestHelpers::main_iterations();
    Scalar::Util::weaken ($open);
    is ($open, undef,
        'garbage collect after show and destroy');
  }
}

exit 0;
