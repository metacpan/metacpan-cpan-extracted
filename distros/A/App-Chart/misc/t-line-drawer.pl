#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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
use App::Chart::Gtk2::Ex::LineClipper;

sub expose {
  my ($area, $event, $userdata) = @_;
  my $drawable = $area->window;
  my $style = $area->get_style;
  my $state = $area->state;
  my $gc = $style->fg_gc ($state);
  my $drawer = App::Chart::Gtk2::Ex::LineClipper->new (drawable => $drawable);
  $drawer->add ($gc, -100,100);
  $drawer->add ($gc, 150,200);
  $drawer->add ($gc, 800,100);
  return 0;
}

my $area = Gtk2::DrawingArea->new;
$area->signal_connect (expose_event => \&expose);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, 300);
$toplevel->add ($area);
$toplevel->show_all;
$toplevel->signal_connect (delete_event => sub { Gtk2->main_quit;
                                                      return 1; # no propagate
                                                    });

Gtk2->main();
