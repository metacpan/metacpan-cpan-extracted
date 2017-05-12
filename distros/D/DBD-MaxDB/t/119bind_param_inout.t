#!perl -w -I./t
#/*!
#  @file           119bind_param_inout.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check bind_param_inout
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

# prepare

print "1..$tests\n";
MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with several columns ()");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII, vc VARCHAR(50) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("prepare INSERT statement");
$sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

my $iur = undef;
my $laur = undef;
my $vcur = undef;

MaxDBTest::beginTest("bind parameters with undef");
$sth->bind_param_inout(1, \$iur, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param_inout(2, \$laur, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param_inout(3, \$vcur, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("execute");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the fetched data is the stuff we inserted");
# select + fetch
@row = $dbh->selectrow_array("SELECT * FROM GerosTestTable") or die "selectrow_array failed $DBI::err $DBI::errstr\n";
# compare
if ((defined $row[0]) || (defined $row[1]) || (defined $row[2])) {
    MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]'). Expected was (NULL, NULL, NULL)});
}
MaxDBTest::endTest();




MaxDBTest::beginTest("DELETE * and prepare new INSERT statement");
$dbh->do("DELETE FROM GerosTestTable") or MaxDBTest::logerror("DELETE * failed $DBI::err $DBI::errstr");
$sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

# values to be inserted:
my $i = 99;
my $la = "la99";
my $vc = "vc99";

MaxDBTest::beginTest("bind parameters with valid index");
$sth->bind_param_inout(1, \$i, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param_inout(2, \$la, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param_inout(3, \$vc, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with invalid index (<= 0)");
$sth->{'PrintError'} = 0;
if ($sth->bind_param_inout(0, \$i, 10)) { MaxDBTest::logerror(qq{bind_param_inout succeeded with p_num = 0. Expected was: fail}); }
if ($sth->bind_param_inout(-5, \$i, 10)) { MaxDBTest::logerror(qq{bind_param_inout succeeded with p_num = -5. Expected was: fail}); }
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("execute");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the fetched data is the stuff we inserted");
# select + fetch
my @row = $dbh->selectrow_array("SELECT * FROM GerosTestTable") or die "selectrow_array failed $DBI::err $DBI::errstr\n";
# compare
if (($row[0] ne $i) || ($row[1] ne $la) || ($row[2] ne $vc)) {
    MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]'). Expected was ($i, '$la', '$vc')});
}
MaxDBTest::endTest();




my $ires = 2004;
my $lares = "erase this";
my $vcres = "erase this";

MaxDBTest::beginTest("prepare SELECT INTO statement");
$sth = $dbh->prepare("SELECT i, la, vc INTO ?, ?, ? FROM GerosTestTable") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters properly");
$sth->bind_param_inout(1, \$ires, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param_inout(2, \$lares, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param_inout(3, \$vcres, 10) or MaxDBTest::logerror(qq{bind_param_inout failed (undef for column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("execute");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the fetched data is the stuff we inserted");
# compare
if (($ires ne $i) || ($lares ne $la) || ($vcres ne $vc)) {
    MaxDBTest::logerror(qq{wrong data returned: ($ires, '$lares', '$vcres'). Expected was ($i, '$la', '$vc')});
}
MaxDBTest::endTest();




MaxDBTest::beginTest("prepare new SELECT INTO statement");
$sth = $dbh->prepare("SELECT i, la, vc INTO ?, ?, ? FROM GerosTestTable") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with invalid max_len -- should fail");
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with invalid reference: undef -- should fail");
MaxDBTest::endTest();


# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

