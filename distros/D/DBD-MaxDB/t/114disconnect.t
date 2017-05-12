#!perl -w -I./t
#/*!
#  @file           114disconnect.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check some methods after having disconnected
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
   $tests = 17;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $rc;
my $err;
my $successful;

print "1..$tests\n";
print " Test 1: connect\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 3: create table with one column\n";
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

# turn warnings of...
$dbh->{'PrintError'} = 0;

print " Test 5: call do with valid SQL statement\n";
$rc = $dbh->do("INSERT INTO GerosTestTable (i) VALUES (1)");
$err = $dbh->err();
$successful = !(defined $rc) && ($err == -11004);
if (!$successful) {
    print "do() returned $rc. Error code is set to $err. The values were expected to be undef and -11004\n";
}
MaxDBTest::Test($successful);

print " Test 6: call selectrow_array with valid SQL statement\n";
my @rowary = $dbh->selectrow_array("SELECT * FROM GerosTestTable");
$err = $dbh->err();
$successful = ($err == -11004);
if (!$successful) {
    print "Error code is set to $err. Expected was -11004\n";
}
MaxDBTest::Test($successful);

print " Test 7: call selectall_arrayref with valid SQL statement\n";
my $aryref = $dbh->selectall_arrayref("SELECT * FROM GerosTestTable");
$err = $dbh->err();
$successful = ($err == -11004);
if (!$successful) {
    print "Error code is set to $err. Expected was -11004\n";
}
MaxDBTest::Test($successful);

print " Test 8: call selectcol_arrayref with valid SQL statement\n";
$aryref = $dbh->selectcol_arrayref("SELECT * FROM GerosTestTable");
$err = $dbh->err();
$successful = ($err == -11004);
if (!$successful) {
    print "Error code is set to $err. Expected was -11004\n";
}
MaxDBTest::Test($successful);

print " Test 9: prepare with valid SQL statement\n";
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (i) VALUES (?)");
$err = $dbh->err();
$successful = ($err == -11004);
if (!$successful) {
    print "Error code is set to $err. Expected was -11004\n";
}
MaxDBTest::Test($successful);

print " Test 10: prepare_cached with valid SQL statement\n";
$sth = $dbh->prepare("INSERT INTO GerosTestTable (i) VALUES (?)");
$err = $dbh->err();
$successful = ($err == -11004);
if (!$successful) {
    print "Error code is set to $err. Expected was -11004\n";
}
MaxDBTest::Test($successful);

print " Test 11: disable AutoCommit\n";
$dbh->{'AutoCommit'} = 0;
MaxDBTest::Test(1);

print " Test 12: commit\n";
$dbh->commit();
$err = $dbh->err();
$successful = ($err == -10821);
if (!$successful) {
    print "Error code is set to $err. Expected was -10821\n";
}
MaxDBTest::Test($successful);

print " Test 13: rollback\n";
$dbh->rollback();
$err = $dbh->err();
$successful = ($err == -10821);
if (!$successful) {
    print "Error code is set to $err. Expected was -10821\n";
}
MaxDBTest::Test($successful);

print " Test 14: disconnect\n";
$rc = $dbh->disconnect();
$err = $dbh->err();
$successful = ($rc == 1) && !(defined $err);
if (!$successful) {
    print "disconnect() returned $rc. Error code is set to $err. The values were expected to be 1 and undef\n";
}
MaxDBTest::Test($successful);

$dbh->{'PrintError'} = 0;

print " Test 15: connect and enable AutoCommit\n";
$dbh = DBI->connect(undef, undef, undef, {AutoCommit => 1}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 16: drop table\n";
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 17: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


