#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

{
  package My::Object;
  use strict;
  use warnings;
  use Gtk2;
  use Glib::Object::Subclass
    'Gtk2::Window',
      signals => { mysig => { param_types   => [],
                              return_type   => undef,
                              flags         => ['run-last','action'],
                              class_closure => \&do_mysig },
                 };
  my $mysig_seen;
  sub do_mysig {
    $mysig_seen = 1;
    print "My::Object mysig runs\n";
  }
}

BEGIN {
  foreach my $i (0 .. 10) {
    print "button $i keyval=",
      Gtk2::Gdk->keyval_from_name("Pointer_Button$i"),"\n";
  }
}

my $label = Gtk2::Label->new;
my $myobj = My::Object->new;

Gtk2::Rc->parse_string (<<'HERE');
binding "foo" {
  bind "x" { "mysig" () }
  bind "X" { "mysig" () }
  bind "Return" { "mysig" () }
  bind "Pointer_Button1" { "mysig" () }
}
HERE
# class "My__Object" binding "foo"

my $foo;
# $myobj->signal_emit ('mysig');

foreach my $class ('Gtk2::Entry', 'My::Object') {
  my $bindingset = Gtk2::BindingSet->by_class($class);
  print "by_class '$class' $bindingset\n";
}

$foo = Gtk2::BindingSet->find('foo');
print "find 'foo' $foo\n";

my $keyname = 'Return';
#my $keyname = 'Pointer_Button1';
my $keyval = Gtk2::Gdk->keyval_from_name($keyname);

{
  print "foo->activate $keyname on myobj\n";
  my $activated = $foo->activate ($keyval, [], $myobj);
  print "  activate result=", ($activated ? "yes" : "no"), "\n";
}
{
  print "myobj->bindings_activate $keyname\n";
  my $activated = $myobj->bindings_activate ($keyval, []);
  print "  bindings_activate result=", ($activated ? "yes" : "no"), "\n";
}

{
  my $keymap = Gtk2::Gdk::Keymap->get_default;
  my @entries = $keymap->get_entries_for_keyval ($keyval);
  require Data::Dumper;
  print Data::Dumper->new([\@entries],['entries'])->Dump;
}

exit 0;
