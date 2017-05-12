#!perl -w -I./t
#/*!
#  @file           143BooleanTypeHandling.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          test handling of booolean data type
#
#\if EMIT_LICENCE
#
#    ========== licence begin  GPL
#    Copyright (C) 2001-2004 SAP AG
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 2
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#    ========== licence end
#
#
#\endif
#*/
use DBI;
use MaxDBTest;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 8;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
print " Test 1: connect\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
MaxDBTest::dropTable($dbh, "BooleantestTable");
MaxDBTest::Test(1);

print " Test 3: create table (a boolean, b boolean)\n";
$dbh->do("CREATE TABLE BooleantestTable (a boolean, b boolean)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: insert one row\n";
my $sth = $dbh->prepare('INSERT INTO BooleantestTable (a,b) VALUES (?,?)') or die "dbh->prepare INSERT failed $DBI::err $DBI::errstr\n";
$sth->execute(0, 1)or die "dbh->prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 5: call selectrow_array (list context) => returned array should have at least 1 entry\n";
my  @row = $dbh->selectrow_array("SELECT * FROM BooleantestTable") or die "selectrow_array failed $DBI::err $DBI::errstr";
if ($#row < 1) { die "selectrow_array returned array with less than 2 entries"; }
MaxDBTest::Test(1);

print " Test 6: compare the fetched data with the stuff we inserted\n";
# row should contain (0, 1)
MaxDBTest::Test(($row[0] == 0 && $row[1] == 1));

print " Test 7: drop table\n";
$dbh->do("DROP TABLE BooleantestTable") or die "DROP TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 8: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


