#!perl -w -I./t
#/*!
#  @file           106selectall_arrayref.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          use selectall_arrayref to fetch data
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
   $tests = 10;
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
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 3: create table (two INTEGER columns)\n";
$dbh->do("CREATE TABLE GerosTestTable (i1 INTEGER, i2 INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: insert ten rows\n";
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (i1, i2) VALUES (?, ?)") or die "prepare failed $DBI::err $DBI::errstr\n";
for (my $i = 0; $i < 10; $i++) {
    # insert one row
    $sth->execute($i, $i+10) or die "execute failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::Test(1);

print " Test 5: call selectall_arrayref\n";
my $ref = $dbh->selectall_arrayref("SELECT * FROM GerosTestTable") or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: compare the fetched data with the stuff we inserted\n";
my $samedata = 1;
my $rowindex = 0;
foreach $row (@$ref) {
    my $offset = 0;
    foreach $colentry (@$row) {
        my $expectedvalue = ($rowindex + $offset);
        if ($colentry != $expectedvalue) {
            print "wrong data returned: $colentry. Expected was $expectedvalue.\n";
            $samedata = 0;
        }
        $offset = 10;
    }
    $rowindex++;
}
MaxDBTest::Test($samedata);

print " Test 7: call selectall_arrayref with bind_values set\n";
$ref = $dbh->selectall_arrayref("SELECT * FROM GerosTestTable WHERE i1 >= ? AND i2 < ?", undef, 0, 1000) or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 8: compare the fetched data with the stuff we inserted\n";
$samedata = 1;
$rowindex = 0;
foreach $row (@$ref) {
    my $offset = 0;
    foreach $colentry (@$row) {
        my $expectedvalue = ($rowindex + $offset);
        if ($colentry != $expectedvalue) {
            print "wrong data returned: $colentry. Expected was $expectedvalue.\n";
            $samedata = 0;
        }
        $offset = 10;
    }
    $rowindex++;
}
MaxDBTest::Test($samedata);

print " Test 9: drop table\n";
$dbh->do("DROP TABLE GerosTestTable");
MaxDBTest::Test(1);

print " Test 10: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


