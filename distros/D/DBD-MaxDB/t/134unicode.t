#!perl -w -I./t
#/*!
#  @file           134unicode.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          insert and fetch unicode data (as ascii and unicode)
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

# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with three columns (LONG UNICODE, VARCHAR(150) UNICODE, INTEGER)");
if ($dbh->{'MAXDB_UNICODE'}) {
    $dbh->do("CREATE TABLE GerosTestTable (la LONG UNICODE, vc VARCHAR(150) UNICODE, i INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();


# run

my ($origla, $origvc) = ("la string", "vc string");

MaxDBTest::beginTest("insert one row as ascii");
if ($dbh->{'MAXDB_UNICODE'}) {
    $dbh->do(qq{INSERT INTO GerosTestTable (la, vc, i) VALUES ('$origla', '$origvc', 1)}) or MaxDBTest::logerror(qq{do INSERT failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("?? fetch as unicode and compare");
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch as ascii and compare");
if ($dbh->{'MAXDB_UNICODE'}) {
    my ($resla, $resvc) = $dbh->selectrow_array(qq{SELECT la, vc FROM GerosTestTable});
    if (($origla ne $resla) || ($origvc ne $resvc)) {
        MaxDBTest::logerror(qq{wrong data returned: ('$resla', '$resvc'). Expected was ('$origla', '$origvc')});
    }
}
MaxDBTest::endTest();

MaxDBTest::beginTest("?? insert another row as unicode");
MaxDBTest::endTest();

MaxDBTest::beginTest("?? fetch as ascii and compare");
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
if ($dbh->{'MAXDB_UNICODE'}) {
    MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

