#!perl -w -I./t
#/*!
#  @file           115quote.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check quote
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

# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with two columns (INTEGER, LONG ASCII)");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


# run

my $index = 0;
sub checkStr($) {
    my $origstr = shift;
    MaxDBTest::loginfo(">>$origstr<< was quoted to >>" . $dbh->quote($origstr) . "<<");
    $dbh->do(qq{INSERT INTO GerosTestTable (i, la) VALUES ($index, } . $dbh->quote($origstr) . ")") or MaxDBTest::logerror(qq{do INSERT failed $DBI::err $DBI::errstr});
    my ($resstr) = $dbh->selectrow_array(qq{SELECT la FROM GerosTestTable WHERE i = $index});
    if ($origstr ne $resstr) {
        MaxDBTest::logerror(qq{wrong data returned: '$resstr'. Expected was '$origstr'});
    }
    $index++;
}

MaxDBTest::beginTest("quote simple string: \"Homer Simpson\" and insert + fetch / compare");
checkStr("Homer Simpson");
MaxDBTest::endTest();

MaxDBTest::beginTest("quote \"Hello \"' World\" and insert + fetch / compare");
checkStr("Hello \"' World");
MaxDBTest::endTest();

MaxDBTest::beginTest("quote string containing all ascii signs and insert + fetch / compare");
checkStr("abcdefghijklmnopqrstuvwxyz0123456789 \n\r°!\"§\$\%\&/()=?*'-:;	#+");
MaxDBTest::endTest();


# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

