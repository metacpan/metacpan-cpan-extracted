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
use App::Chart::Gtk2::Symlist;
use App::Chart::DBI;

require App::Chart::Gtk2::Symlist::All;
my $all_list = App::Chart::Gtk2::Symlist::All->instance;

my $dbh = App::Chart::DBI->instance;
my $symbol_list = $dbh->selectcol_arrayref ('SELECT symbol FROM info');

foreach my $symbol (@$symbol_list) {
  $all_list->insert_symbol ($symbol);
}

exit 0;
