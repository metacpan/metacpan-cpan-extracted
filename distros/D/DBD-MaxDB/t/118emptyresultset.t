#!perl -w -I./t
#/*!
#  @file           118emptyresultset.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          perform query that delivers an empty result set. How do the select methods react?
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
   $tests = 9;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with one column");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII, vc VARCHAR(50) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("insert one row");
MaxDBTest::execSQL($dbh, "INSERT INTO GerosTestTable (i, la, vc) VALUES (1, 'la1', 'vc1')") or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("selectrow_array with SELECT stmt which returns empty set");
my @row = $dbh->selectrow_array("SELECT * FROM GerosTestTable WHERE i = 3");
MaxDBTest::endTest();

MaxDBTest::beginTest("selectall_arrayref with SELECT stmt which returns empty set");
my $allref = $dbh->selectall_arrayref("SELECT * FROM GerosTestTable WHERE i = 3");
MaxDBTest::endTest();

MaxDBTest::beginTest("selectcol_arrayref with SELECT stmt which returns empty set");
my $colref = $dbh->selectcol_arrayref("SELECT * FROM GerosTestTable WHERE i = 3");
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

