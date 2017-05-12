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
use Gtk2 '-init';
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->signal_connect (expose_event => sub {
                             print "toplevel expose\n";
                           });

my $layout = Gtk2::Layout->new;
$layout->set_size_request (200,200);
$toplevel->add ($layout);
$layout->signal_connect (expose_event => sub {
                           print "drawingarea expose ",
                             $layout->window, "\n";
                         });

my $area = Gtk2::DrawingArea->new;
$area->set_size_request (100,100);
$layout->add ($area);
$area->signal_connect (expose_event => sub {
                         print "sub-drawingarea expose ",
                           $area->window, "\n";
                       });

$toplevel->add_events (['key-press-mask']);
$toplevel->signal_connect
  (key_press_event =>
   sub {
     my ($widget, $event) = @_;
     $toplevel->queue_draw;
   });

$toplevel->show_all;
Gtk2->main;
