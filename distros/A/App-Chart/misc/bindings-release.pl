#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::BindingBits;

use FindBin;
my $progname = $FindBin::Script;

Gtk2::Rc->parse_string (<<'HERE');
binding "mybindings" {
  bind "Pointer_Button1" { "mysig" ('plain button') }
  bind "<Alt>Pointer_Button1" { "mysig" ('with alt') }
  bind "<Release>Pointer_Button3" { "mysig" ('release 3') }
}
HERE

{
  package MyToplevel;
  use strict;
  use warnings;
  use Gtk2;
  use Glib::Object::Subclass
    'Gtk2::Window',
      signals => { mysig => { param_types   => ['Glib::String'],
                              return_type   => undef,
                              flags         => ['run-last','action'],
                              class_closure => \&do_mysig },
                 };
  my $mysig_seen;
  sub do_mysig {
    my ($self, $str) = @_;
    print "My::Object mysig runs: $str\n";
  }
}

my $toplevel = MyToplevel->new;
$toplevel->add_events (['button-press-mask', 'button-release-mask']);

$toplevel->signal_connect
  (button_press_event =>
   sub {
     my ($toplevel, $event) = @_;
     my $modifiers = $event->get_state;
     print "press modifiers ", ref($modifiers), ", $modifiers\n";
     my $found = App::Chart::Gtk2::Ex::BindingBits::activate_button_event
       ('mybindings', $event, $toplevel);
     print "  activate $found\n";
   });
$toplevel->signal_connect
  (button_release_event =>
   sub {
     my ($toplevel, $event) = @_;
     my $modifiers = $event->get_state;
     print "release modifiers ", ref($modifiers), ", $modifiers\n";
     my $found = App::Chart::Gtk2::Ex::BindingBits::activate_button_event
       ('mybindings', $event, $toplevel);
     print "  activate $found\n";
   });

$toplevel->show_all;
Gtk2->main;
