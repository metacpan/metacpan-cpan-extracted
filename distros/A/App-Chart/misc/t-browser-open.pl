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
use Data::Dumper;
use App::Chart::Gtk2::GUI;

my $uri;
$uri = 'file:///var/www/index.html';
$uri = 'http://localhost/index.html';
my $screen = undef;
$screen = Gtk2::Gdk::Screen->get_default;

{
  print "URI: $uri\n";
  App::Chart::Gtk2::GUI::browser_open ($uri);
  Gtk2->main;
  exit 0;
}

{
  print "URI: $uri\n";
  if (eval { Gtk2::show_uri ($screen, $uri); 1 }) {
    print "ok\n";
  } else {
    print Dumper($@);
  }
  Gtk2->main;
  exit 0;
}
