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


use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use App::Chart;
use App::Chart::Gtk2::AboutDialog;

use FindBin;
my $progname = $FindBin::Script;

use Data::Dumper;
print "$progname: ",Data::Dumper->Dump([\%INC],['INC']);
say "$progname: App::Chart loaded from $INC{'App/Chart.pm'}";

my $toplevel = Gtk2::Window->new;
$toplevel->show_all;

App::Chart::Gtk2::AboutDialog->new->present;

# my $about = App::Chart::Gtk2::AboutDialog->instance;
# my $about = App::Chart::Gtk2::AboutDialog->instance_for_screen ($toplevel);
# $about->signal_connect (destroy => sub {
#                           say "$progname: dialog destroy, do main_quit()";
#                           Gtk2->main_quit;
#                         });
Gtk2->main;

say "$progname: instance() is ", App::Chart::Gtk2::AboutDialog->instance;
exit 0;
