#!perl -w -I./t
#/*!
#  @file           136AutoCommit.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          checks AutoCommit property
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
   $tests = 21;
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


# run

MaxDBTest::beginTest("AutoCommit := true");
$dbh->{'AutoCommit'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with one column");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("insert one column (i=1)");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (i) VALUES (1)}) or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("call commit(): should succeed with warning");
$dbh->{'Warn'} = 0;
$dbh->commit() or
    MaxDBTest::logerror(qq{commit failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("call rollback(): should succeed with warning");
$dbh->rollback() or
    MaxDBTest::logerror(qq{rollback failed $DBI::err $DBI::errstr});
$dbh->{'Warn'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("connect");
$dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if data was really inserted");
$dbh->selectrow_array("SELECT i FROM GerosTestTable WHERE i = 1") or
    MaxDBTest::logerror("data (i=1) was not inserted as expected");
MaxDBTest::endTest();

MaxDBTest::beginTest("AutoCommit := false");
$dbh->{'AutoCommit'} = 0;
MaxDBTest::endTest();

MaxDBTest::beginTest("insert one column (i=3)");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (i) VALUES (3)}) or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("call commit(): should succeed");
$dbh->commit() or
    MaxDBTest::logerror(qq{commit failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("insert one column (i=5)");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (i) VALUES (5)}) or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("call rollback(): should succeed");
$dbh->rollback() or
    MaxDBTest::logerror(qq{rollback failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("insert one column (i=7)");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (i) VALUES (7)}) or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("connect");
$dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the right data was inserted");
$dbh->selectrow_array("SELECT i FROM GerosTestTable WHERE i = 3") or
    MaxDBTest::logerror("data (i=3) was not inserted as expected");
$dbh->{'PrintError'} = 0;
if ($dbh->selectrow_array("SELECT i FROM GerosTestTable WHERE i = 5")) {
    MaxDBTest::logerror("the insertion of data (i=5) was not rolled back as expected");
}
if ($dbh->selectrow_array("SELECT i FROM GerosTestTable WHERE i = 7")) {
    MaxDBTest::logerror("the insertion of data (i=7) was not rolled back as expected");
}
$dbh->{'PrintError'} = 1;
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

