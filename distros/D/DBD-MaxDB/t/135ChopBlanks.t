#!perl -w -I./t
#/*!
#  @file           135ChopBlanks.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check ChopBlanks property
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

MaxDBTest::beginTest("create table with one column (CHAR(30))");
$dbh->do("CREATE TABLE GerosTestTable (c CHAR(30))") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

my $data = "   too   many  blanks         "; # 30 signs
my $datachopped = "   too   many  blanks";

MaxDBTest::beginTest("insert one row with blanks at the beginning and at the end");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (c) VALUES ('$datachopped')}) or MaxDBTest::logerror("INSERT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("set ChopBlanks to false");
$dbh->{'ChopBlanks'} = 0;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: blanks should not be chopped");
my ($resdata) = $dbh->selectrow_array("SELECT * FROM GerosTestTable");
if ($resdata ne $datachopped) {
    MaxDBTest::logerror(qq{Wrong data returned: '$resdata'. Expected was '$data'});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("set ChopBlanks to true");
$dbh->{'ChopBlanks'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: blanks should be chopped");
($resdata) = $dbh->selectrow_array("SELECT * FROM GerosTestTable");
if ($resdata ne $datachopped) {
    MaxDBTest::logerror(qq{Wrong data returned: '$resdata'. Expected was '$datachopped'});
}
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

