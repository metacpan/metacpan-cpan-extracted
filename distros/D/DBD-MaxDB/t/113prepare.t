#!perl -w -I./t
#/*!
#  @file           113prepare.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          checks prepare
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

print "1..$tests\n";
print " Test 1: connect\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 3: prepare and execute create table with one column\n";
my $sth = $dbh->prepare("CREATE TABLE GerosTestTable (i INTEGER)") or die "prepare CREATE TABLE failed $DBI::err $DBI::errstr\n";
$sth->execute() or die "execute CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: prepare UPDATE statement\n";
$sth = $dbh->prepare("UPDATE GerosTestTable SET i = ? WHERE i = ?") or die "prepare UPDATE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 5: prepare SELECT statement\n";
$sth = $dbh->prepare("SELECT * FROM GerosTestTable WHERE i = ?") or die "prepare SELECT failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: prepare DELETE statement\n";
$sth = $dbh->prepare("DELETE FROM GerosTestTable WHERE i = ?") or die "prepare DELETE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 7: prepare invalid statement\n";
$dbh->{'PrintError'} = 0;
$sth = $dbh->prepare("wrong SQL ?");
$dbh->{'PrintError'} = 1;
MaxDBTest::Test(!(defined $sth));

print " Test 8: prepare 10000 INSERT statements and store them\n";
my @handlelist;
# set array size to 10000
$#handlelist = 9999;
for (my $i=0; $i<10000; $i++) {
    $handlelist[$i] = $dbh->prepare("INSERT INTO GerosTestTable (i) VALUES (?)");
}
MaxDBTest::Test(1);

print " Test 9: execute some of the statements\n";
my @randomindexlist = (7264, 9163, 4437, 1254, 0, 2434, 7523, 1733, 1245, 7347, 3746, 1632, 2933, 2363, 3763, 6543);
foreach $index (@randomindexlist) {
    my $rc = $handlelist[$index]->execute($index) or die "execute failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::Test(1);

print " Test 10: check if the right data was inserted\n";
my $ref = $dbh->selectcol_arrayref("SELECT * FROM GerosTestTable") or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";

my $samedata = 1;
my $rowindex = 0;
foreach $rowentry (@$ref) {
    if ($rowentry != $randomindexlist[$rowindex]) {
        print "wrong data returned: $rowentry. Expected was $randomindexlist[$rowindex].\n";
        $samedata = 0;
    }
    $rowindex++;
}
MaxDBTest::Test($samedata);

print " Test 11: drop table\n";
$dbh->do("DROP TABLE GerosTestTable") or die "DROP TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 12: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
