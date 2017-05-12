#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use DBI;
use Data::Dumper;

use App::Chart::Database;
use App::Chart::DBI;

# my $dbh = DBI->connect("dbi:SQLite:dbname=~/Chart/database.sqdb","","",
#                        {RaiseError=>1}
#                       );
my $dbh = App::Chart::DBI->instance();

{
  my $ary_ref = $dbh->selectall_arrayref('SELECT symbol, currency, name FROM info');
  print Dumper($ary_ref);
}

$dbh->disconnect;
exit 0;

