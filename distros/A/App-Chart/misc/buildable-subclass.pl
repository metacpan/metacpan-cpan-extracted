#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

package MyThing;
use strict;
use warnings;
use Gtk2;

use Glib::Object::Subclass
  'Gtk2::Button',
  interfaces => [ 'Gtk2::Buildable' ];

sub CUSTOM_TAG_START {
  my ($self, $builder, $child, $tagname) = @_;
  print "hello from CUSTOM_TAG_START\n";
  if ($tagname eq 'mynewtag') {
    # ... make and return a parser
  }
  # how to chain to superclass buildable ?
  return undef;
}

package main;
use strict;
use warnings;
use Gtk2 '-init';

my $builder = Gtk2::Builder->new;
$builder->add_from_string ('
<interface>
  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <child>
      <object class="MyThing" id="button">
        <signal name="clicked" handler="do_click"/>
        <accelerator key="x" signal="clicked"/>

        <child>
          <object class="GtkLabel" id="label">
            <property name="label">Press Me</property>
          </object>
        </child>
      </object>
    </child>
  </object>
</interface>
');

sub do_click { print "the button was clicked\n"; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;
