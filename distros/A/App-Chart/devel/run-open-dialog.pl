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
use App::Chart::Gtk2::OpenDialog;

use FindBin;
my $progname = $FindBin::Script;

my $open = App::Chart::Gtk2::OpenDialog->new;
$open->signal_connect (destroy => sub { Gtk2->main_quit });

# $open->signal_connect
#   (symbol_open => sub {
#      my ($open, $symbol, $symlist) = @_;
#      print "$progname: symbol_open signal: $symbol $symlist\n";
#    });
# $open->signal_connect
#   (symbol_new => sub {
#      my ($open, $symbol) = @_;
#      print "$progname: symbol_new signal: $symbol";
#    });

$open->show;
App::Chart::chart_dirbroadcast()->listen;
Gtk2->main;
exit 0;
