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
use Data::Dumper;
use POSIX;
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::GdkColorAlloc;

{
  my $c = Gtk2::Gdk::Color->new (1, 2, 3);
  print Dumper ($c);
}

{
  my $o = 1234;
  my $c = bless \$o, 'Foo';
  print Dumper ($c);
}

if (0) {
  my $visual = Gtk2::Gdk::Visual->get_best;
  my $cmap = Gtk2::Gdk::Colormap->new ($visual, 1);
  my $c = App::Chart::Gtk2::Ex::GdkColorAlloc->new (colormap => $cmap, color => 'red');
  print Dumper ($c);
  print "cmap ", $c->colormap||'undef', "\n";
}

if (1) {
  my $visual = Gtk2::Gdk::Visual->get_best;
  my $cmap = Gtk2::Gdk::Colormap->new ($visual, 1);
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->set_colormap ($cmap);
  my $c = App::Chart::Gtk2::Ex::GdkColorAlloc->new (colormap => $cmap, color => 'red');
  print Dumper ($c);
  print "cmap ", $c->colormap||'undef', "\n";
  $widget->destroy;
  $widget = undef;
  $cmap = undef;
  print Dumper ($c);
  print "cmap ", $c->colormap||'undef', "\n";
}
