#!perl -w -I./t
#/*!
#  @file           123fetchall_arrayref.t
#  @author         GeroD,MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          check fetchall_arrayref
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
   $tests = 14;
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

MaxDBTest::beginTest("create table with two columns (INTEGER, VARCHAR(40))");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER, c VARCHAR(40) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

# strings to be inserted
my @data = qw/abcdefgh GerosTestString superperlstring a1 a2 a33 5274 shgrtb hallohallo hallo/;

MaxDBTest::beginTest("insert ten rows");
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, c) VALUES (?, ?)") or die "prepare SELECT failed $DBI::err $DBI::errstr\n";
my $i=0;
foreach $str (@data) {
    $sth->execute($i, $str) or die "execute failed $DBI::err $DBI::errstr\n";
    $i++;
}
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("prepare SELECT statement");
$sth = $dbh->prepare("SELECT * FROM GerosTestTable") or die "prepare SELECT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("execute statement");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("call finish");
$sth->finish() or MaxDBTest::logerror(qq{finish failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("check if fetchall_arrayref fails");
$sth->{'PrintError'} = 0;
my $fail =$sth->fetchall_arrayref();
if (($#$fail) != -1) {
    MaxDBTest::logerror(qq{Array should be empty. Found was $#$fail});
}
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("prepare new SELECT statement");
$sth = $dbh->prepare("SELECT * FROM GerosTestTable") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("execute statement");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("fetchall_arrayref and compare");
my $arrref = $sth->fetchall_arrayref() or MaxDBTest::logerror(qq{fetchall_arrayref failed $DBI::err $DBI::errstr});
$i=0;
foreach $rowref (@$arrref) {
    my ($int, $char) = @$rowref;
    if (($int != $i) || ($char ne $data[$i])) {
        MaxDBTest::logerror(qq{wrong data was returned: ($int, '$char'). Expected was ($i, '$data[$i]')});
    }
    $i++;
}
MaxDBTest::endTest();

MaxDBTest::beginTest("check if fetchall_arrayref fails");
$sth->{'PrintError'} = 0;
if ($sth->fetchrow_arrayref()) {
    MaxDBTest::logerror(qq{fetchall_array succeeded. Expected was fail});
}
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();


# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

