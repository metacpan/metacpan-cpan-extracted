#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

{
  package foo;
  use Gtk2;
  use Glib::Object::Subclass 'Gtk2::Button';
}

my $signame = Gtk2::Viewport->set_scroll_adjustments_signal;
print "viewports run $signame for set_scroll_adjustments()\n";


my $signame = Gtk2::Button->activate_signal;
print "button emit $signame for activate()\n";

my $signame = foo->activate_signal;
print "foo emit $signame for activate()\n";

foo->activate_signal(undef);

my $signame = Gtk2::Button->activate_signal;
print "button emit $signame for activate()\n";

my $signame = foo->activate_signal;
print "foo emit $signame for activate()\n";
