#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;


Gtk2::Rc->parse_string (<<HERE);
binding "my_keys" {
  bind "<ctrl>x" { "move-cursor" (logical-positions, -1, 0) }
}
class "GtkEntry" binding "my_keys"
HERE


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $entry = Gtk2::Entry->new;
$entry->signal_connect
  (key_press_event => sub {
     my ($entry, $event) = @_;
     print "$progname: hardware_keycode=",$event->hardware_keycode,
       " group=", $event->group, "\n";
     return Gtk2::EVENT_PROPAGATE;
   });
$entry->signal_connect
  (activate => sub {
     my ($entry, $event) = @_;
     print "$progname: entry activate\n";
   });
$vbox->pack_start ($entry, 0,0,0);

my $keyval_left = Gtk2::Gdk->keyval_from_name('Left');

{
  my $button = Gtk2::Button->new_with_label ("keyval left");
  $button->signal_connect
    (clicked => sub {
       Glib::Timeout->add
           (3000, sub {
              print "$progname: keyval left\n";
              $entry->bindings_activate ($keyval_left, []);
              return 0;
            });
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("event left");
  $button->signal_connect
    (clicked => sub {
       my $event = Gtk2::Gdk::Event->new ('key-press');
       $event->window ($entry->window);
       # $event->hardware_keycode (100); # Left
       $event->hardware_keycode (36); # Return
       $event->group (0);
       $event->keyval ($keyval_left);
       $event->set_state ([]);
       Glib::Timeout->add
           (3000, sub {
              print "$progname: event left\n";
              print "  dispatch ",($entry->bindings_activate_event($event)
                                   ? "yes" : "no"), "\n";
              return 0;
            });
     });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
