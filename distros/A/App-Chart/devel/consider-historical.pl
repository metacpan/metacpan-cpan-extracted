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
use Data::Dumper;
use App::Chart::DBI;
use App::Chart::Download;
use App::Chart::Gtk2::Symlist;

# my $symbol_list = ['BHP.AX', 'IPG.AX', 'PBL.AX', 'MGR.AX', 'CL.NYM',
#                    'CSM.AX', 'MGW.AX' ];

my $all_list = App::Chart::Gtk2::Symlist->new_from_key ('all');
my $symbol_list = $all_list->symbols;
print Dumper($symbol_list);

my $dbh = App::Chart::DBI->instance;
$dbh->do ('UPDATE info SET historical=0');

App::Chart::Download::consider_historical ($symbol_list);
exit 0;
