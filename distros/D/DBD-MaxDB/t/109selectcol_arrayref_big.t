#!perl -w -I./t
#/*!
#  @file           109selectcol_arrayref_big.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          use selectcol_arrayref to fetch a lot of data
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

print " Test 3: create table (1x INTEGER + 1x LONG ASCII + 1x VARCHAR(100) ASCII)\n";
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII, vc VARCHAR(100) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: insert 1000 rows (23..25 Byte each string)\n";
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare failed $DBI::err $DBI::errstr\n";
for (my $i = 0; $i < 1000; $i++) {
    # insert one row
    my $laval = qq{la_str $i test test test}; # contains 23..25 signs (depending on i)
    my $vcval = qq{vc_str $i test test test}; # contains 23..25 signs (depending on i)
    $sth->execute($i, $laval, $vcval) or die "execute failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::Test(1);

print " Test 5: call selectcol_arrayref (first column is INTEGER)\n";
my $ref = $dbh->selectcol_arrayref("SELECT * FROM GerosTestTable") or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: compare the fetched data with the stuff we inserted\n";
my $samedata = 1;
my $rowindex = 0;
foreach $rowentry (@$ref) {
    if ($rowentry != $rowindex) {
        print "wrong data returned: $rowentry. Expected was $rowindex.\n";
        $samedata = 0;
    }
    $rowindex++;
    if (!$samedata) { last; } # avoid printing too much...
}
MaxDBTest::Test($samedata);

print " Test 7: call selectcol_arrayref (first column is LONG)\n";
$ref = $dbh->selectcol_arrayref("SELECT la, vc, i FROM GerosTestTable") or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 8: compare the fetched data with the stuff we inserted\n";
$samedata = 1;
$rowindex = 0;
foreach $rowentry (@$ref) {
    my $expectedla = qq{la_str $rowindex test test test};
    if ($rowentry ne $expectedla) {
        print "wrong data returned: '$rowentry'. Expected was '$expectedla'.\n";
        $samedata = 0;
    }
    $rowindex++;
    if (!$samedata) { last; } # avoid printing too much...
}
MaxDBTest::Test($samedata);

print " Test 9: call selectcol_arrayref (first column is VARCHAR)\n";
$ref = $dbh->selectcol_arrayref("SELECT vc, i, la FROM GerosTestTable") or die "selectall_arrayref failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 10: compare the fetched data with the stuff we inserted\n";
$samedata = 1;
$rowindex = 0;
foreach $rowentry (@$ref) {
    my $expectedvc = qq{vc_str $rowindex test test test};
    if ($rowentry ne $expectedvc) {
        print "wrong data returned: '$rowentry'. Expected was '$expectedvc'.\n";
        $samedata = 0;
    }
    $rowindex++;
    if (!$samedata) { last; } # avoid printing too much...
}
MaxDBTest::Test($samedata);

print " Test 11: drop table\n";
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::Test(1);

print " Test 12: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


