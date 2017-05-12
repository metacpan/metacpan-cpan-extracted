#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use 5.010;
use Gtk2 '-init';
use App::Chart::Gtk2::Symlist::All;
use App::Chart::Gtk2::Ticker;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

# 'BHP.AX', 'TEL.NZ', 'BBW.AX'
my $ticker = App::Chart::Gtk2::Ticker->new
  (symlist => App::Chart::Gtk2::Symlist::All->instance);
$toplevel->add ($ticker);

# $ticker->menu;
$ticker->signal_connect (menu_popup => sub {
                           print "$progname: menu-popup action signal runs\n";
                         });
$ticker->signal_connect (menu_popup => sub {
                           print "$progname: menu-popup action signal runs more\n";
                         });
print "$progname: get_name ",$ticker->get_name//'undef',"\n";
{ local $,=' '; print "$progname: class_path ",$ticker->class_path,"\n"; }
{ my @sigs = Glib::Type->list_signals (ref($ticker));
  print "$progname: signals: ";
  local $,=' '; say map {$_->{'signal_name'}} @sigs;
}

# use Data::Dumper;
# print Dumper($ticker);

# { my $req = $ticker->size_request;
#   print $req->width,"x",$req->height,"\n";
# }
# $ticker->queue_resize;
# { my $req = $ticker->size_request;
#   print $req->width,"x",$req->height,"\n";
# }

#$ticker->signal_emit ('menu-popup', 0, 'centre');

my $keyname = 'Pointer_Button3';
my $event = Gtk2::Gdk::Event->new ('key-press');
my $keyval = Gtk2::Gdk->keyval_from_name($keyname);
print "$progname: keyval $keyval\n";
my $display = $ticker->get_display;
my $keymap = Gtk2::Gdk::Keymap->get_for_display ($display);
my @keys = $keymap->get_entries_for_keyval ($keyval);
use Data::Dumper;
print "$progname: ", Dumper(\@keys),"\n";
# @keys or die;
# $event->keyval($keyval);
# $event->group($keys[0]->{'group'});
# $event->hardware_keycode($keys[0]->{'keycode'});



$toplevel->show_all;
Gtk2->main;
exit 0;
