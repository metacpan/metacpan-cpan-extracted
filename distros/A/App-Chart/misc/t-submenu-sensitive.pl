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
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new;
$hbox->add ($vbox);

my $menubar = Gtk2::MenuBar->new;
$hbox->pack_start ($menubar, 1,1,0);

my $submenu = Gtk2::Menu->new;
$submenu->add (Gtk2::TearoffMenuItem->new);

my $subitem = Gtk2::MenuItem->new_with_label ('SubItem');
$submenu->add ($subitem);

$submenu->add (Gtk2::SeparatorMenuItem->new);

my $submenu2 = Gtk2::Menu->new;

my $item = Gtk2::MenuItem->new_with_label ('Item 1');
$menubar->add ($item);
$item->set_submenu ($submenu);

my $insens = App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive->new ($item);
require Data::Dumper;
print Data::Dumper::Dumper($item);
print Data::Dumper::Dumper([$submenu->get_children]);

if (0) {
  my $item = Gtk2::MenuItem->new_with_label ('Item 2');
  $menubar->add ($item);
  $item->set_submenu ($submenu);
}

{
  my $button = Gtk2::CheckButton->new_with_label ('SubItem Visible');
  $button->set_active (1);
  $button->signal_connect (toggled => sub {
                             $subitem->set(visible => $button->get_active);
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::CheckButton->new_with_label ('SubMenu 1or2');
  $button->set_active (1);
  $button->signal_connect (toggled => sub {
                             $item->set_submenu ($button->get_active
                                                 ? $submenu : $submenu2);
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}


$toplevel->show_all;
Gtk2->main;
exit 0;
