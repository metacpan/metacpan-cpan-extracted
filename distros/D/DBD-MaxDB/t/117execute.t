#!perl -w -I./t
#/*!
#  @file           117execute.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check execute (not all columns bound / columns bound several times / no conversion possible)
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

MaxDBTest::beginTest("bind some of the columns");
$sth->bind_param(1, $i) or MaxDBTest::logerror(qq{bind_param failed (column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param(3, $vc) or MaxDBTest::logerror(qq{bind_param failed (column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
if ($dbh->{'MAXDB_UNICODE'}) {
  $sth->bind_param(4, $lu) or MaxDBTest::logerror(qq{bind_param failed (column 4, LONG UNICODE) $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("execute should fail [not all columns bound]");
$sth->{'PrintError'} = 0;
if ($sth->execute()) { MaxDBTest::logerror(qq{execute succeeded. Expected was: fail [not all columns bound]}); }
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("check if we can fetch anything...");
# select and fetch
$dbh->{'PrintError'} = 0;
my @row = $dbh->selectrow_array("SELECT * FROM GerosTestTable");
$dbh->{'PrintError'} = 1;
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare new INSERT statement");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc, lu, vcu) VALUES (?, ?, ?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
} else {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("bind all columns");
$sth->bind_param(1, $i) or MaxDBTest::logerror(qq{bind_param failed (column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param(2, $la) or MaxDBTest::logerror(qq{bind_param failed (column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param(3, $vc) or MaxDBTest::logerror(qq{bind_param failed (column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
if ($dbh->{'MAXDB_UNICODE'}) {
  $sth->bind_param(4, $lu) or MaxDBTest::logerror(qq{bind_param failed (column 4, LONG UNICODE) $DBI::err $DBI::errstr});
  $sth->bind_param(5, $vcu) or MaxDBTest::logerror(qq{bind_param failed (column 5, VARCHAR UNICODE) $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

# values to be inserted:
my $xi = 99;
my $xla = "la99";
my $xvc = "vc99";
my $xlu = "lu99";
my $xvcu = "vcu99";

MaxDBTest::beginTest("execute with bind_values");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth->execute($xi, $xla, $xvc, $xlu, $xvcu) or MaxDBTest::logerror(qq{execute failed $DBI::err $DBI::errstr});
} else {
    $sth->execute($xi, $xla, $xvc) or MaxDBTest::logerror(qq{execute failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("re-execute with bind_values");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth->execute($xi, $xla, $xvc, $xlu, $xvcu) or MaxDBTest::logerror(qq{re-execute failed $DBI::err $DBI::errstr});
} else {
    $sth->execute($xi, $xla, $xvc) or MaxDBTest::logerror(qq{re-execute failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("check which data is inserted");
# select and fetch
@row = $dbh->selectrow_array("SELECT * FROM GerosTestTable") or MaxDBTest::logerror(qq{selectrow_array failed $DBI::err $DBI::errstr});
# compare
if ($dbh->{'MAXDB_UNICODE'}) {
    if ($#row != 4) {
        my $numcolumns = $#row + 1;
        MaxDBTest::logerror(qq{selectrow_array returned $numcolumns columns. Expected were 5});
    } else {
        if (($row[0] ne $i) || ($row[1] ne $la) || ($row[2] ne $vc) || ($row[3] ne $lu) || ($row[4] ne $vcu)) {
            MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]', '$row[3]', '$row[4]'). Expected was ($i, '$la', '$vc', '$lu', '$vcu')});
        }
    }
} else {
    if ($#row != 2) {
        my $numcolumns = $#row + 1;
        MaxDBTest::logerror(qq{selectrow_array returned $numcolumns columns. Expected were 3});
    } else {
        if (($row[0] ne $i) || ($row[1] ne $la) || ($row[2] ne $vc)) {
            MaxDBTest::logerror(qq{wrong data returned: ($row[0], '$row[1]', '$row[2]'). Expected was ($i, '$la', '$vc')});
        }
    }
}
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare new INSERT statement");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc, lu, vcu) VALUES (?, ?, ?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
} else {
    $sth = $dbh->prepare("INSERT INTO GerosTestTable (i, la, vc) VALUES (?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("bind all columns (one INTEGER column bound with not convertable string)");
$sth->bind_param(1, "This is not an integer") or MaxDBTest::logerror(qq{bind_param failed (column 1, INTEGER) $DBI::err $DBI::errstr});
$sth->bind_param(2, $la) or MaxDBTest::logerror(qq{bind_param failed (column 2, LONG ASCII) $DBI::err $DBI::errstr});
$sth->bind_param(3, $vc) or MaxDBTest::logerror(qq{bind_param failed (column 3, VARCHAR ASCII) $DBI::err $DBI::errstr});
if ($dbh->{'MAXDB_UNICODE'}) {
  $sth->bind_param(4, $lu) or MaxDBTest::logerror(qq{bind_param failed (column 4, LONG UNICODE) $DBI::err $DBI::errstr});
  $sth->bind_param(5, $vcu) or MaxDBTest::logerror(qq{bind_param failed (column 5, VARCHAR UNICODE) $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("execute -- should fail");
$sth->{'PrintError'} = 0;
if ($sth->execute()) { MaxDBTest::logerror(qq{execute succeeded. Expected was: fail [conversion error]}); }
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare SELECT INTO statement");
if ($dbh->{'MAXDB_UNICODE'}) {
    $sth = $dbh->prepare("SELECT i, la, vc, lu, vcu INTO ?, ?, ?, ?, ? FROM GerosTestTable") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
} else {
    $sth = $dbh->prepare("SELECT i, la, vc INTO ?, ?, ? FROM GerosTestTable") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("bind all columns with bind_param -- should fail [we need to bind out parameter]");
$sth->{'PrintError'} = 0;
if ($sth->bind_param(1, $i)) { MaxDBTest::logerror(qq{bind_param succeeded (column 1, INTEGER). Expected was: fail}); }
if ($sth->bind_param(2, $la)) { MaxDBTest::logerror(qq{bind_param succeeded (column 2, LONG ASCII). Expected was: fail}); }
if ($sth->bind_param(3, $vc)) { MaxDBTest::logerror(qq{bind_param succeeded (column 3, VARCHAR ASCII). Expected was: fail}); }
if ($dbh->{'MAXDB_UNICODE'}) {
  if ($sth->bind_param(4, $lu)) { MaxDBTest::logerror(qq{bind_param succeeded (column 4, LONG UNICODE). Expected was: fail}); }
  if ($sth->bind_param(5, $vcu)) { MaxDBTest::logerror(qq{bind_param succeeded (column 5, VARCHAR UNICODE). Expected was: fail}); }
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
