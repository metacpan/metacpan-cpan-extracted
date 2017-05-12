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

use strict;
use warnings;
use Data::Dumper;
use DBI::Const::GetInfoType;
use App::Chart;
use App::Chart::DBI;

my $dbh = App::Chart::DBI->instance();

print "DB\n";
{
  print "  name: ", $dbh->get_info($GetInfoType{SQL_DBMS_NAME}), "\n";
  print "  version: ", $dbh->get_info($GetInfoType{SQL_DBMS_VER}), "\n";
}
print "\n";

print "daily\n";
{
  my $sth = $dbh->primary_key_info ('', '', 'daily');
  my $aref = $sth->fetchall_arrayref ({});
  print "primary_key_info: ", Dumper ($aref);
}
{
  my $sth = $dbh->column_info (undef, undef, 'daily', 'date');
  if (! defined $sth) {
    print "no dbh->column_info: ", $dbh->errstr // '(no errstr)', "\n";
  } else {
    my $h = $sth->fetchall_hashref;
    $sth->finish;
    print "date column: ", Dumper (\$h);
  }
}
print "\n";

print "type_info_all\n";
{
  my $aref = $dbh->type_info_all;
  print Dumper (\$aref);
}
print "\n";

print "database stats\n";

{
  my $query = 'SELECT symbol,COUNT(*) FROM daily GROUP BY symbol ORDER BY COUNT(*)';
  my $aref = $dbh->selectall_arrayref ("$query DESC LIMIT 5");
  print Data::Dumper->new([$aref],['most daily records'])->Indent(1)->Dump;
  $aref = $dbh->selectall_arrayref ("$query ASC LIMIT 5");
  @$aref = reverse @$aref;
  print Data::Dumper->new([$aref],['fewest daily records'])->Indent(1)->Dump;
}

exit 0;
