#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


# 'temp' window type sets save-under, and 'input-output' is supposed to have
# the server obey save-under, but it still generates exposes.


use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{ my $label = Gtk2::Label->new ('Click and drag for temporary window');
  $vbox->pack_start ($label, 0,0,0);
}

my $area = Gtk2::DrawingArea->new;
$area->set_flags ('can-focus');
$vbox->pack_start ($area, 1,1,0);

my $display = $area->get_display;
my $root = Gtk2::Gdk->get_default_root_window;
print "root window $root\n";

my $tempwin = Gtk2::Gdk::Window->new ($root,
                                      { window_type => 'temp',
                                        width => 40,
                                        height => 30,
                                        wmclass_name => 'Temporary window',
                                        wmclass_class => 'Temporary window',
                                        window_class => 'input-output',
                                        override_redirect => 1
                                      });
# $tempwin->set_background ($tempwin, $color);

$display->flush;
system ('xwininfo', '-id', $tempwin->get_xid);
system ('xprop', '-id', $tempwin->get_xid, "WM_CLASS");
print "\n";

$area->add_events (['button-press-mask',
                    'button-motion-mask',
                    'button-release-mask']);
$area->signal_connect
  (button_press_event =>
   sub {
     my ($area, $event) = @_;
     print "show\n";
     my ($area_root_x, $area_root_y) = $area->window->get_origin;
     $tempwin->show;
     $tempwin->move ($area_root_x + $event->x,
                     $area_root_y + $event->y);
   });

$area->signal_connect
  (motion_notify_event =>
   sub {
     my ($area, $event) = @_;
     my ($area_root_x, $area_root_y) = $area->window->get_origin;
     $tempwin->move ($area_root_x + $event->x,
                     $area_root_y + $event->y);
   });

$area->signal_connect
  (button_release_event =>
   sub {
     my ($area, $event) = @_;
     print "hide\n";
     $tempwin->hide;
   });

$area->signal_connect
  (expose_event =>
   sub {
     my ($area, $event) = @_;
     print "area expose\n";
     my $region = $event->region;
     foreach my $rect ($region->get_rectangles) {
       print "  ",$rect->x,",",$rect->y," ",
         $rect->width,"x",$rect->height,"\n";
     }
     return Gtk2::EVENT_PROPAGATE;
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
