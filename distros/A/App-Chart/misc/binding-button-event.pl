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

Gtk2::Rc->parse_string (<<'HERE');
binding "my_bindings" {
  bind "Pointer_Button1" { "mysignal" ('plain button') }
  bind "<Alt>Pointer_Button1" { "mysignal" ('with alt') }
  bind "<Release>Pointer_Button3" { "mysignal" ('release 3') }
}
HERE

{
  package MyWidget;
  use strict;
  use warnings;
  use Gtk2;
  use Glib::Object::Subclass
    'Gtk2::Layout',
      signals => { button_press_event   => \&do_button_event,
                   button_release_event => \&do_button_event,
                  mysignal => { param_types   => ['Glib::String'],
                                 return_type   => undef,
                                 flags         => ['run-last','action'],
                                 class_closure => \&do_mysignal },
                 };

  sub INIT_INSTANCE {
    my ($self) = @_;
    $self->add_events (['button-press-mask', 'button-release-mask']);
  }

  sub do_button_event {
    my ($self, $event) = @_;
    print "MyWidget ",$event->type," ",$event->button,
      " invoking activate_button_event()\n";

    my $found = App::Chart::Gtk2::Ex::BindingBits::activate_button_event
      ('my_bindings', $event, $self);
    if ($found) {
      print "  binding found and run\n";
    } else {
      print "  no binding found\n";
    }
    shift->signal_chain_from_overridden(@_);
  }

  sub do_mysignal {
    my ($self, $str) = @_;
    print "  mysignal runs: $str\n";
  }
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (200, 200);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $mywidget = MyWidget->new;
$toplevel->add ($mywidget);

my $label = Gtk2::Label->new ('Press mouse buttons');
$mywidget->put ($label, 10, 10);

$toplevel->show_all;
Gtk2->main;
