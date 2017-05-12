#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use App::Chart::Series::Database;
use App::Chart::Gtk2::SeriesTreeView;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (600, 300);

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $scrolled = Gtk2::ScrolledWindow->new;
$vbox->pack_start ($scrolled, 1,1,0);

my $series = App::Chart::Series::Database->new ('BHP.AX');
print "$progname: series $series\n";

my $treeview = App::Chart::Gtk2::SeriesTreeView->new (series => $series);
$scrolled->add ($treeview);

$treeview->add_events (['button-press-mask',
                        'button-motion-mask',
                        'button-release-mask']);
$treeview->signal_connect
  (button_press_event => sub {
     my ($treeview, $event) = @_;
     print "$progname: button";
     if ($event->button == 3) {
       require Gtk2::Ex::Dragger;
       my $dragger = ($treeview->{'dragger'} ||=
                      Gtk2::Ex::Dragger->new
                      (widget        => $treeview,
                       vadjustment   => $scrolled->get_vadjustment,
                       cursor        => 'sb-v-double-arrow',
                       confine       => 1));
       $dragger->start ($event);
       return 1; # Gtk2::EVENT_STOP
     }
     return Gtk2::EVENT_PROPAGATE;
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
