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
use App::Chart::Gtk2::WeblinkMenu;

my $symbol = $ARGV[0] || 'BHP.AX';

my $toplevel = Gtk2::Window->new ('toplevel');

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $weblink_menu = App::Chart::Gtk2::WeblinkMenu->new (symbol => $symbol);

my $entry = Gtk2::Entry->new;
$entry->set_text ($symbol);
$entry->signal_connect (activate => sub {
                          $weblink_menu->set (symbol => $entry->get_text);
                        });
$vbox->pack_start ($entry, 1,1,0);

my $menubar = Gtk2::MenuBar->new;
$vbox->pack_start ($menubar, 1,1,0);

my $item = Gtk2::MenuItem->new_with_label ('Web ...');
$item->set_submenu ($weblink_menu);
$menubar->add ($item);

$toplevel->show_all;

# immediate popup, but causes a disconcerting pointer/keyboard grab
# $weblink_menu->popup (undef, undef, undef, undef, 0, 0);

Gtk2->main;
exit 0;
