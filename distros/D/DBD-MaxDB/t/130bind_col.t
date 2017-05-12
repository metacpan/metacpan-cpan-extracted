#!perl -w -I./t
#/*!
#  @file           130bind_col.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check bind_col
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

# prepare

print "1..$tests\n";
MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with a lot of columns");
$dbh->do(q{CREATE TABLE GerosTestTable (i1 INTEGER, la1 LONG ASCII, vc1 VARCHAR(50) ASCII,
i2 INTEGER, la2 LONG ASCII, vc2 VARCHAR(50) ASCII,
i3 INTEGER, la3 LONG ASCII, vc3 VARCHAR(50) ASCII,
i4 INTEGER, la4 LONG ASCII, vc4 VARCHAR(50) ASCII)}) or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

# data to be inserted - we use it to compare it to the fetched data later on...
my @data;
$#data = 9; # set array size

MaxDBTest::beginTest("insert ten rows");
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (i1, la1, vc1, i2, la2, vc2, i3, la3, vc3, i4, la4, vc4) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
for (my $i=0; $i<10; $i++) {
    # prepare data to be inserted
    my @row = ($i, qq{la1$i}, qq{vc1$i}, $i+10, qq{la2$i}, qq{vc2$i}, $i+20, qq{la3$i}, qq{vc3$i}, $i+30, qq{la4$i}, qq{vc4$i});
    $data[$i] = [@row];
    
    # do insert it
    $sth->execute(@row) or MaxDBTest::logerror("execute INSERT failed $DBI::err $DBI::errstr");
}
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("prepare and execute SELECT statement");
$sth = $dbh->prepare("SELECT * FROM GerosTestTable") or MaxDBTest::logerror("prepare SELECT failed $DBI::err $DBI::errstr");
$sth->execute() or MaxDBTest::logerror("execute SELECT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

my @resdata;
$#resdata = 11; # we have 12 columns...

MaxDBTest::beginTest("bind all columns");
$sth->bind_col(1, \$resdata[0]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(2, \$resdata[1]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(3, \$resdata[2]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(4, \$resdata[3]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(5, \$resdata[4]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(6, \$resdata[5]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(7, \$resdata[6]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(8, \$resdata[7]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(9, \$resdata[8]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(10, \$resdata[9]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(11, \$resdata[10]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(12, \$resdata[11]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare the data we fetched with the data we inserted");
for (my $rowindex=0; $rowindex<10; $rowindex++) {
    # fetch
    $sth->fetch() or MaxDBTest::logerror("fetch failed $DBI::err $DBI::errstr");
    
    # compare
    for (my $colindex=0; $colindex<12; $colindex++) {
        if ($resdata[$colindex] ne $data[$rowindex][$colindex]) {
            MaxDBTest::logerror(qq{wrong data was fetched: '$resdata[$colindex]'. Expected was '$data[$rowindex][$colindex]'.});
            last;
        }
    }
}
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare and execute SELECT statement");
$sth = $dbh->prepare("SELECT i2, vc1, la4, vc3, i1, vc4 FROM GerosTestTable") or MaxDBTest::logerror("prepare SELECT failed $DBI::err $DBI::errstr");
$sth->execute() or MaxDBTest::logerror("execute SELECT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("bind some of the columns");
# we would have to bind 6 columns
$sth->bind_col(1, \$resdata[0]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(3, \$resdata[2]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
$sth->bind_col(4, \$resdata[3]) or MaxDBTest::logerror("bind_col failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare the data we fetched with the data we inserted");
for (my $rowindex=0; $rowindex<10; $rowindex++) {
    # fetch
    $sth->fetch() or MaxDBTest::logerror("fetch failed $DBI::err $DBI::errstr");

    # compare
    if ($resdata[0] ne $data[$rowindex][3]) { # i2
        MaxDBTest::logerror(qq{wrong data was fetched: '$resdata[0]'. Expected was '$data[$rowindex][3]'.});
    }
    if ($resdata[2] ne $data[$rowindex][10]) { # la4
        MaxDBTest::logerror(qq{wrong data was fetched: '$resdata[2]'. Expected was '$data[$rowindex][10]'.});
    }
    if ($resdata[3] ne $data[$rowindex][8]) { # vc3
        MaxDBTest::logerror(qq{wrong data was fetched: '$resdata[3]'. Expected was '$data[$rowindex][8]'.});
    }
}
# check if the others are untouched...
if ($resdata[1] ne $data[9][1]) { # original: la1, last select: vc1
    MaxDBTest::logerror(qq{data was touched: '$resdata[1]'. Expected was '$data[9][1]'.});
}
if ($resdata[4] ne $data[9][4]) {
    MaxDBTest::logerror(qq{data was touched: '$resdata[4]'. Expected was '$data[9][4]'.});
}
if ($resdata[5] ne $data[9][5]) {
    MaxDBTest::logerror(qq{data was touched: '$resdata[5]'. Expected was '$data[9][5]'.});
}
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare and execute SELECT statement");
$sth = $dbh->prepare("SELECT la4, vc2, i1, i4, vc1 FROM GerosTestTable") or MaxDBTest::logerror("prepare SELECT failed $DBI::err $DBI::errstr");
$sth->execute() or MaxDBTest::logerror("execute SELECT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("bind columns with invalid index -- should fail");
#$dbh->trace(3);

eval {
  $sth->bind_col(0, \$resdata[0]);
}; MaxDBTest::logerror("bind_col succeeded. Expected was fail") if (!$@);

eval {
  $sth->bind_col(-5, \$resdata[0]);
}; MaxDBTest::logerror("bind_col succeeded. Expected was fail") if (!$@);

eval {
  $sth->bind_col(6, \$resdata[0]);
}; MaxDBTest::logerror("bind_col succeeded. Expected was fail") if (!$@);

$sth->{'PrintError'} = 1;
$sth->finish();
MaxDBTest::endTest();

# release

MaxDBTest::beginTest("drop table");
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$sth->{'PrintError'} = 0;
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
#$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

