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
use Scope::Guard;
use Data::Dumper;
use Gtk2 '-init';

my $widget;
my $id;

$widget = Gtk2::Label->new;
my $w2 = Gtk2::Button->new;


my $a1 = $widget->requisition;
my $a2 = $widget->requisition;
print Dumper($a1);
print Dumper($a2);


$w2->signal_connect ('destroy', sub {
                       my ($w2, $widget) = @_;
                       print "disconnect $widget ", $widget->get_flags, "\n";
                       $widget->signal_handler_disconnect ($id);
                     }, $widget);

$id = $widget->signal_connect ('grab_broken_event', \&_do_grab_broken);

Glib::Idle->add (sub { $widget = undef; Gtk2->main_quit });
Gtk2->main;

$widget = undef;
print Dumper($a1);
print Dumper($a2);

exit 0;
