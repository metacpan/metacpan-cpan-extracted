#!perl -w -I./t
#/*!
#  @file           116bind_param.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check bind_param
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
#use Devel::Peek;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 14;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $sth;
my $rc;

print "1..$tests\n";

# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::loginfo("We have a " . (($dbh->{'MAXDB_UNICODE'}) ? "unicode" : "ascii") . " database");
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with several columns ()");
if ($dbh->{'MAXDB_UNICODE'}) {
    $dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII, vc VARCHAR(50) ASCII, lu LONG UNICODE, vcu VARCHAR(50) UNICODE)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
} else {
    $dbh->do("CREATE TABLE GerosTestTable (i INTEGER, la LONG ASCII, vc VARCHAR(50) ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("prepare INSERT statement");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc, lu, vcu) VALUES (?, ?, ?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
} else {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

# values to be inserted:
my $i = 99;
my $la = "la99";
my $vc = "vc99";
my $lu = "lu99";
my $vcu = "vcu99";

MaxDBTest::beginTest("bind parameters with valid index");
$sth->bind_param(1, $i) or MaxDBTest::logerror(qq{bind_param failed (column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param(2, $la) or MaxDBTest::logerror(qq{bind_param failed (column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param(3, $vc) or MaxDBTest::logerror(qq{bind_param failed (column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
if ($dbh->{'MAXDB_UNICODE'}) {
  $sth->bind_param(4, $lu) or MaxDBTest::logerror(qq{bind_param failed (column 4, LONG UNICODE) $DBI::err $DBI::errstr});
  $sth->bind_param(5, $vcu) or MaxDBTest::logerror(qq{bind_param failed (column 5, VARCHAR UNICODE) $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with invalid index (<= 0)");
$sth->{'PrintError'} = 0;
if ($sth->bind_param(0, $i)) { MaxDBTest::logerror(qq{bind_param succeeded with p_num = 0. Expected was: fail}); }
if ($sth->bind_param(-5, $i)) { MaxDBTest::logerror(qq{bind_param succeeded with p_num = -5. Expected was: fail}); }
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("execute");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the inserted data is the stuff we inserted");
# select + fetch
my @row = $dbh->selectrow_array("SELECT * FROM GerosTestTable") or die "selectrow_array failed $DBI::err $DBI::errstr\n";
# compare
if ($dbh->{'MAXDB_UNICODE'}) {
    if (($row[0] ne $i) || ($row[1] ne $la) || ($row[2] ne $vc) || ($row[3] ne $lu) || ($row[4] ne $vcu)) {
        MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]', '$row[3]', '$row[4]'). Expected was ($i, '$la', '$vc', '$lu', '$vcu')});
    }
} else {
    if (($row[0] ne $i) || ($row[1] ne $la) || ($row[2] ne $vc)) {
        MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]'). Expected was ($i, '$la', '$vc')});
    }
}
MaxDBTest::endTest();



MaxDBTest::beginTest("DELETE * and prepare new INSERT statement");
$dbh->do("DELETE FROM GerosTestTable") or MaxDBTest::logerror("DELETE * failed $DBI::err $DBI::errstr");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc, lu, vcu) VALUES (?, ?, ?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
} else {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with undef");
$sth->bind_param(1, undef) or MaxDBTest::logerror(qq{bind_param failed (undef for column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param(2, undef) or MaxDBTest::logerror(qq{bind_param failed (undef for column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param(3, undef) or MaxDBTest::logerror(qq{bind_param failed (undef for column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
if ($dbh->{'MAXDB_UNICODE'}) {
  $sth->bind_param(4, undef) or MaxDBTest::logerror(qq{bind_param failed (undef for column 4, LONG UNICODE) $DBI::err $DBI::errstr});
  $sth->bind_param(5, undef) or MaxDBTest::logerror(qq{bind_param failed (undef for column 5, VARCHAR UNICODE) $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("execute");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("check if the inserted data is the stuff we inserted");
# select + fetch
@row = $dbh->selectrow_array("SELECT * FROM GerosTestTable") or die "selectrow_array failed $DBI::err $DBI::errstr\n";
# compare
if ($dbh->{'MAXDB_UNICODE'}) {
    if (($row[0]) || ($row[1]) || ($row[2]) || ($row[3]) || ($row[4])) {
        MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]', '$row[3]', '$row[4]'). Expected was (NULL, NULL, NULL, NULL, NULL)});
    }
} else {
    if (($row[0]) || ($row[1]) || ($row[2])) {
        MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]'). Expected was (NULL, NULL, NULL)});
    }
}
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();


