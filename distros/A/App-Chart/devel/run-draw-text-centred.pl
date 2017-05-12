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


# Try drawing with App::Chart::Gtk2::GUI::draw_text_centred(), into both windowed
# and no-window widgets.
#

use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::GUI;

Gtk2::Gdk::Window->set_debug_updates (1);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

{
  my $gap = Gtk2::DrawingArea->new;
  $gap->set_size_request (-1, 20);
  $vbox->pack_start ($gap, 0,0,0);
  my $black = $gap->get_style->black;
  $gap->modify_bg ($gap->state, $black);
}
{
  my $area = Gtk2::DrawingArea->new;
  $area->set_size_request (100, 50);
  $area->signal_connect (expose_event => sub {
                           my ($widget, $event) = @_;
                           App::Chart::Gtk2::GUI::draw_text_centred
                               ($widget, $event, 'hello');
                         });
  $vbox->pack_start ($area, 1,1,0);
}
{
  my $gap = Gtk2::DrawingArea->new;
  $gap->set_size_request (-1, 1);
  $vbox->pack_start ($gap, 0,0,0);
  my $black = $gap->get_style->black;
  $gap->modify_bg ($gap->state, $black);
}
{
  my $area = Gtk2::DrawingArea->new;
  $area->set_size_request (100, 50);
  $area->signal_connect (expose_event => sub {
                           my ($widget, $event) = @_;
                           App::Chart::Gtk2::GUI::draw_text_centred
                               ($widget, $event, 'world');
                         });
  $vbox->pack_start ($area, 1,1,0);
}
{
  my $gap = Gtk2::DrawingArea->new;
  $gap->set_size_request (-1, 1);
  $vbox->pack_start ($gap, 0,0,0);
  my $black = $gap->get_style->black;
  $gap->modify_bg ($gap->state, $black);
}
{
  my $area = Gtk2::Label->new;
  $area->set_size_request (100, 50);
  $area->signal_connect (expose_event => sub {
                           my ($widget, $event) = @_;
                           App::Chart::Gtk2::GUI::draw_text_centred
                               ($widget, $event, 'blah');
                         });
  $vbox->pack_start ($area, 1,1,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
