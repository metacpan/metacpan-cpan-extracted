#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

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
use App::Chart::SymbolHistory;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new;
$toplevel->add($hbox);

my $back_button = Gtk2::Button->new_with_label ("Back");
$back_button->signal_connect
  (clicked => sub {
   });
$hbox->pack_start ($back_button, 0,0,0);

my $forward_button = Gtk2::Button->new_with_label ("Forward");
$forward_button->signal_connect
  (clicked => sub {
   });
$hbox->pack_start ($forward_button, 0,0,0);

my $history = App::Chart::SymbolHistory->new
  (back_button    => $back_button,
   forward_button => $forward_button);
$history->signal_connect (menu_activate => \&_do_symbol_history_menu_activate);

$history->goto ('AAA');
$history->goto ('BBB');
$history->goto ('CCC');

$toplevel->show_all;
Gtk2->main;
exit 0;
