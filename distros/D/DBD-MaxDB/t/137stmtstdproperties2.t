#!perl -w -I./t
#/*!
#  @file           137stmtstdproperties2.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          a more detailed check of some stmt properties. Extension to 057stmtstdproperties.t
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
   $tests = 19;
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

MaxDBTest::beginTest("create table with five columns (2x INTEGER, 1x LONG ASCII, 2x VARCHAR(30) ASCII)");
$dbh->do("CREATE TABLE GerosTestTable (i1 INTEGER NOT NULL, i2 INTEGER, la LONG ASCII, vc1 VARCHAR(30) ASCII, vc2 VARCHAR(30) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("prepare INSERT statement without placeholders");
my $preparestr = "INSERT INTO GerosTestTable (i1, la) VALUES (3, 'Hello World')";
my $sth = $dbh->prepare($preparestr) or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("NUM_OF_FIELDS should be 0");
if ($sth->{'NUM_OF_FIELDS'} != 0) {
    MaxDBTest::logerror(qq{NUM_OF_FIELDS is $sth->{'NUM_OF_FIELDS'}. Expected was 0});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NUM_OF_PARAMS should be 0");
if ($sth->{'NUM_OF_PARAMS'} != 0) {
    MaxDBTest::logerror(qq{NUM_OF_PARAMS is $sth->{'NUM_OF_PARAMS'}. Expected was 0});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NAME should be empty");
if ($#{$sth->{'NAME'}} != -1) {
    MaxDBTest::logerror(qq{Count of NAME is }.($#{$sth->{'NAME'}}+1).qq{. Expected was 0});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("Statement should contain the right string");
if ($sth->{'Statement'} ne $preparestr) {
    MaxDBTest::logerror(qq{Statement is '$sth->{'Statement'}'. Expected was '$preparestr'});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("prepare INSERT statement with two placeholders (the second for a NOT NULL column)");
$sth = $dbh->prepare("INSERT INTO GerosTestTable (vc2, i1, la) VALUES (?, ?, 'Hustenbonbon')") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("NUM_OF_PARAMS should be 2");
if ($sth->{'NUM_OF_PARAMS'} != 2) {
    MaxDBTest::logerror(qq{NUM_OF_PARAMS is $sth->{'NUM_OF_PARAMS'}. Expected was 2});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NULLABLE should be empty");
if ($#{$sth->{'NULLABLE'}} != -1) {
    MaxDBTest::logerror(qq{Count of NULLABLE is }.($#{$sth->{'NULLABLE'}}+1).qq{. Expected was 0});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("prepare SELECT statement with three resulting columns (one alias, one column NOT NULL)");
$sth = $dbh->prepare("SELECT vc1, la as LONGASCIICOL, i1 FROM GerosTestTable") or die "prepare SELECT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("NUM_OF_FIELDS should be 3");
if ($sth->{'NUM_OF_FIELDS'} != 3) {
    MaxDBTest::logerror(qq{NUM_OF_FIELDS is $sth->{'NUM_OF_FIELDS'}. Expected was 3});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NUM_OF_PARAMS should be 0");
if ($sth->{'NUM_OF_PARAMS'} != 0) {
    MaxDBTest::logerror(qq{NUM_OF_PARAMS is $sth->{'NUM_OF_PARAMS'}. Expected was 2});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NAME_lc and NAME_uc should deliver the right column names (including the alias)");
if ($#{$sth->{'NAME_lc'}} == 2) {
    if (($sth->{'NAME_lc'}->[0] ne "vc1") || ($sth->{'NAME_lc'}->[1] ne "longasciicol") || ($sth->{'NAME_lc'}->[2] ne "i1")) {
        MaxDBTest::logerror(qq{Wrong column names returned ($sth->{'NAME_lc'}->[0], $sth->{'NAME_lc'}->[1], $sth->{'NAME_lc'}->[2]). Expected were (vc1, longasciicol, i1)});
    }
} else {
    MaxDBTest::logerror(qq{Count of NAME_lc is }.($#{$sth->{'NAME_lc'}}+1).qq{. Expected was 3});
}
if ($#{$sth->{'NAME_uc'}} == 2) {
    if (($sth->{'NAME_uc'}->[0] ne "VC1") || ($sth->{'NAME_uc'}->[1] ne "LONGASCIICOL") || ($sth->{'NAME_uc'}->[2] ne "I1")) {
        MaxDBTest::logerror(qq{Wrong column names returned ($sth->{'NAME_uc'}->[0], $sth->{'NAME_uc'}->[1], $sth->{'NAME_uc'}->[2]). Expected were (VC1, LONGASCIICOL, I1)});
    }
} else {
    MaxDBTest::logerror(qq{Count of NAME_uc is }.($#{$sth->{'NAME_uc'}}+1).qq{. Expected was 3});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("TYPE should return some values");
if ($#{$sth->{'TYPE'}} != 2) {
    MaxDBTest::logerror(qq{Count of TYPE is }.($#{$sth->{'TYPE'}}+1).qq{. Expected was 3});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("NULLABLE should return the right values (twice true, once false)");
if ($#{$sth->{'NULLABLE'}} == 2) {
    if (($sth->{'NULLABLE'}->[0] != 1) || ($sth->{'NULLABLE'}->[1] != 1) || ($sth->{'NULLABLE'}->[2] != 0)) {
        MaxDBTest::logerror(qq{NULLABLE returned ($sth->{'NULLABLE'}->[0], $sth->{'NULLABLE'}->[1], $sth->{'NULLABLE'}->[2]). Expected was (1, 1, 0)});
    }
} else {
    MaxDBTest::logerror(qq{Count of NULLABLE is }.($#{$sth->{'NULLABLE'}}+1).qq{. Expected was 3});
}
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

