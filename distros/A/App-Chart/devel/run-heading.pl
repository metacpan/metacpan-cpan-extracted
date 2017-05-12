#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use App::Chart::Gtk2::Heading;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (1000, -1);

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $series = App::Chart::Series::Database->new ('BHP.AX');

my $heading = App::Chart::Gtk2::Heading->new (series_list => [ $series ]);
$vbox->pack_start ($heading, 1,1,0);

$toplevel->show_all;
Gtk2->main();
exit 0;
