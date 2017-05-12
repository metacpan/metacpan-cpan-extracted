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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

use App::Chart::Gtk2::Ex::ToplevelSingleton;

use Gtk2;
BEGIN {
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  my $have_display = Gtk2->init_check;
  $have_display or
    plan skip_all => 'due to no DISPLAY available';
}

plan tests => 8;


#------------------------------------------------------------------------------

{
  package MyToplevel;
  use Glib::Object::Subclass 'Gtk2::Window';
  use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
}

#------------------------------------------------------------------------------

my $display = Gtk2::Gdk::Screen->get_default->get_display;
my $screen = $display->get_default_screen;

{
  is_deeply([Gtk2::Window->list_toplevels],[],'no toplevels');
  my $t1 = MyToplevel->instance;
  my $t2 = MyToplevel->instance;
  is ($t1->get_display, $display, "default display");
  is ($t1, $t2, 'instance same return');
  $t1->destroy;
  if ($t2 != $t1) { $t2->destroy; }
}

# {
#   is_deeply([Gtk2::Window->list_toplevels],[],'no toplevels');
#   my $d2 = Gtk2::Gdk::Display->open (undef);
#   my $t1 = MyToplevel->instance;
#   my $t2 = MyToplevel->instance_for_display ($d2);
#   is ($t2->get_display, $d2, "second display");
#   isnt ($t1, $t2, 'different on second display');
#   $t1->destroy;
#   if ($t2 != $t1) { $t2->destroy; }
#   $d2->close;
# }
# 
# {
#   is_deeply([Gtk2::Window->list_toplevels],[],'no toplevels');
#   my $d2 = Gtk2::Gdk::Display->open (undef);
#   my $t2 = MyToplevel->instance_for_display ($d2);
#   is ($t2->get_display, $d2, "initial display - moved to default display");
#   $t2->set_screen ($display->get_default_screen);
#   is ($t2->get_display, $display, "display - moved to default display");
#   my $t1 = MyToplevel->instance;
#   is ($t1, $t2, 'instance - moved to default display');
#   $t1->destroy;
#   if ($t2 != $t1) { $t2->destroy; }
#   $d2->close;
# }

{
  is_deeply([Gtk2::Window->list_toplevels],[],'no toplevels');
  my $d2 = Gtk2::Gdk::Display->open (undef);
  my $s2 = $d2->get_default_screen;
  my $t1 = MyToplevel->instance;

  {
    my $t2 = MyToplevel->instance_for_screen ($s2);
    is ($t2->get_display, $d2, "second display");
    isnt ($t1, $t2, 'different on second display');
    if ($t2 != $t1) { $t2->destroy; }
  }
  {
    my $t2 = MyToplevel->instance_for_screen ($d2);
    is ($t2->get_display, $d2, "second display");
    isnt ($t1, $t2, 'different on second display');
    if ($t2 != $t1) { $t2->destroy; }
  }

  $t1->destroy;
  $d2->close;
}


exit 0;
