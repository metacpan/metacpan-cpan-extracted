#!perl -w -I./t
#/*!
#  @file           104do_insert_update_delete.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          use do() for inserting, updating and deleting rows
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
   $tests = 12;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $rc;

print "1..$tests\n";
print " Test 1: connect\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table using do\n";
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 3: create table using do => should return 0\n";
$rc = $dbh->do("CREATE TABLE GerosTestTable (i1 INTEGER, i2 INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 0));

print " Test 4: insert first row using do => should return 1\n";
$rc = $dbh->do("INSERT INTO GerosTestTable (i1, i2) VALUES (1, 2)") or die "INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 1));

print " Test 5: insert second row using do with bind_values being set => should return 1 or -1\n";
my @insertval = (3, 4);
$rc = $dbh->do("INSERT INTO GerosTestTable (i1, i2) VALUES (?, ?)", undef, @insertval) or die "INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 1) || ($rc == -1));

print " Test 6: update one row using do => should return 1\n";
$rc = $dbh->do("UPDATE GerosTestTable SET i2 = 6 WHERE i1 = 3") or die "UPDATE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 1));

print " Test 7: update one row using do with bind_values being set => should return 1\n";
$rc = $dbh->do("UPDATE GerosTestTable SET i2 = ? WHERE i1 = ?", undef, 5, 1) or die "UPDATE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 1) || ($rc == -1));

print " Test 8: update using invalid SQL statement => should return undef\n";
$dbh->{'PrintError'} = 0;
$rc = $dbh->do("wrong SQL");
$dbh->{'PrintError'} = 1;
MaxDBTest::Test(!(defined $rc));

print " Test 9: delete both rows using do => should return 2 or -1\n";
$rc = $dbh->do("DELETE FROM GerosTestTable") or die "DELETE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 2 || $rc == -1));

print " Test 10: delete using do => should return 0E0\n";
$rc = $dbh->do("DELETE FROM GerosTestTable");
MaxDBTest::Test(($rc == "0E0"));

print " Test 11: drop table using do => should return 0\n";
$rc = $dbh->do("DROP TABLE GerosTestTable") or die "DROP TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(($rc == 0));

print " Test 12: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


