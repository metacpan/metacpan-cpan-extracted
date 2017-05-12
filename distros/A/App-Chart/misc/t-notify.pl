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
use Glib;
use App::Chart::Glib::Ex::DirBroadcast;
use Data::Dumper;

App::Chart::Glib::Ex::DirBroadcast->directory ('/tmp/t-notify');

App::Chart::Glib::Ex::DirBroadcast->connect ('abc', sub { print "abc $$\n"; });
App::Chart::Glib::Ex::DirBroadcast->connect ('def', sub { print "def $$\n"; });
App::Chart::Glib::Ex::DirBroadcast->connect ('fdjk', sub { print "fdjk $$\n"; });

if (@ARGV && $ARGV[0] eq 'child') {
  print "child $$\n";
  App::Chart::Glib::Ex::DirBroadcast->send ('abc');
  App::Chart::Glib::Ex::DirBroadcast->send ('def');
  exit 0;
}

print "parent $$\n";
App::Chart::Glib::Ex::DirBroadcast->listen;
system $^X, $0, 'child';

App::Chart::Glib::Ex::DirBroadcast->send ('fdjk');

# my $context = Glib::MainContext->default;
my $mainloop = Glib::MainLoop->new;
$mainloop->run;
exit 0;
