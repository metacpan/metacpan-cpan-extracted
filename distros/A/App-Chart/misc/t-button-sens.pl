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


# button doesn't work until re-enter after going re-sensitive

use strict;
use warnings;
use Gtk2 '-init';
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $button = Gtk2::Button->new_with_label ('Press');
$toplevel->add ($button);
$button->signal_connect
  (clicked => sub {
     print "insensitive\n";
     $button->set_sensitive (0);
     Glib::Timeout->add (1000, sub {
                           print "sensitive again\n";
                           $button->set_sensitive (1);
                           return 1; # Glib::SOURCE_CONTINUE
                         });
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
