#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2015, 2016, 2017 Kevin Ryde

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
use App::Chart::Latest;
use App::Chart::LatestHandler;
use Data::Dumper;

$App::Chart::option{'verbose'} = 2;

my $symbol = $ARGV[0] || 'BHP.AX';
print "$symbol\n";

# require App::Chart::Gtk2::Job::Latest;
# my $job = App::Chart::Gtk2::Job::Latest->start ([$symbol]);
# sleep (10);

App::Chart::LatestHandler->download ([$symbol]);

$Data::Dumper::Sortkeys = 1;
my $latest = App::Chart::Latest->get ($symbol);
print Dumper($latest);
print "short_datetime   ",$latest->short_datetime(),"\n";
print "formatted_volume ",$latest->formatted_volume()//'undef',"\n";

exit 0;
