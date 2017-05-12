#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use App::Chart::Glib::Ex::ChildPid;

use FindBin;
my $progname = $FindBin::Script;

my $pid = fork();
if (! $pid) { sleep 2; exit 5; }

my $c = App::Chart::Glib::Ex::ChildPid->new (pid => $pid);
$c->signal_connect (exited => sub { print "$progname: exited signal\n"; });

my $mainloop = Glib::MainLoop->new;
$mainloop->run;
exit 0;
