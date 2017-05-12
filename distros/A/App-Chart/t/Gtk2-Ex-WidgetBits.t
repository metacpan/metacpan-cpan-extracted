#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Ex::WidgetBits;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 1;

MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------
# error_bell()

my $label = Gtk2::Label->new ('Foo');
diag "has_screen '",$label->has_screen,"'";
# diag "display_name ",Gtk2::Gdk->get_display;
# App::Chart::Gtk2::Ex::WidgetBits::error_bell($label);

App::Chart::Gtk2::Ex::WidgetBits::error_bell($label);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->add($label);
$label->realize;
App::Chart::Gtk2::Ex::WidgetBits::error_bell($label);
ok(1);

exit 0;
