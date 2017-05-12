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


# Run Business::ISIN over all the ISINs recorded in the database.
#

use strict;
use warnings;
use Business::ISIN;
use App::Chart::DBI;

my $dbh = App::Chart::DBI->instance;
my $aref = $dbh->selectall_arrayref
  ('SELECT symbol,isin FROM info WHERE isin NOT NULL');
my $bi = Business::ISIN->new;

my $count = 0;
foreach my $elem (@$aref) {
  my ($symbol, $isin) = @$elem;
  print "$symbol $isin\n";
  $count++;

  $bi->set ($isin);
  if ($bi->is_valid) {
    print "  ok\n";
  } else {
    print "  invalid: ", $bi->error, "\n";
  }
}
print "total $count\n";
exit 0;
