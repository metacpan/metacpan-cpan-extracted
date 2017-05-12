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


# Run up a SymlistRadioMenu.


use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::SymlistRadioMenu;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $left_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($left_vbox, 0,0,0);

my $right_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($right_vbox, 1,1,0);

my $menu = App::Chart::Gtk2::SymlistRadioMenu->new;
$menu->signal_connect
  (notify => sub {
     my ($menu, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "$progname: set $pname to ", $menu->get($pname)||'undef', "\n";
   });

$menu->set (symlist => App::Chart::Gtk2::Symlist->new_from_key ('favourites'));

my $menubar = Gtk2::MenuBar->new;
$left_vbox->pack_start ($menubar, 0,0,0);
my $item = Gtk2::MenuItem->new_with_label ('Menu');
$item->set_submenu ($menu);
$menubar->add ($item);

$toplevel->show_all;
Gtk2->main;
exit 0;
