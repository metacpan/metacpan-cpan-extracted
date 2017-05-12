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
use App::Chart::Gtk2::PreferencesDialog;
use App::Chart::Gtk2::Ex::ToplevelBits;

use FindBin;
my $progname = $FindBin::Script;


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $button = Gtk2::Button->new_with_label ('Popup');
$toplevel->add ($button);
$button->signal_connect
  (clicked => sub {
     print "$progname: popup\n";
     App::Chart::Gtk2::Ex::ToplevelBits::popup ('App::Chart::Gtk2::PreferencesDialog',
                                                screen => $button);
   });

$toplevel->show_all;

App::Chart::Gtk2::Ex::ToplevelBits::popup ('App::Chart::Gtk2::PreferencesDialog',
                                           screen => $toplevel);
Gtk2->main;
exit 0;
