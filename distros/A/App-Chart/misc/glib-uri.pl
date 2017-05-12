#!/usr/bin/perl -w

# Copyright 2009, 2016 Kevin Ryde

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

# RFC 
use strict;
use warnings;
use Data::Dumper;
use Glib;

#my $uri = Glib::filename_to_uri ("/tmp/foo.html", "\x{263A}.com");
my $uri = Glib::filename_to_uri ("/tmp/foo.html", "foo.com");
print $uri,"\n";

$uri = Glib::filename_to_uri ("/\x{E2}\x{98}\x{BA}/foo.html", '');
print $uri,"\n";

my ($f,$h) = Glib::filename_from_uri ($uri);
print Dumper($f);
print Dumper($h);

my @a = Glib::filename_from_uri ('file:///foo.txt');
print Dumper(\@a);

