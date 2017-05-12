#!perl -w -I./t
#/*!
#  @file           131bind_columns.t
#  @author         GeroD,MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          check bind_columns
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
   $tests = 13;
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

MaxDBTest::beginTest("bind_columns");
$sth->bind_columns(\$resdata[0], \$resdata[1], \$resdata[2], \$resdata[3], \$resdata[4], \$resdata[5],
    \$resdata[6], \$resdata[7], \$resdata[8], \$resdata[9], \$resdata[10], \$resdata[11]) or MaxDBTest::logerror("bind_columns failed $DBI::err $DBI::errstr");
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
$sth = $dbh->prepare("SELECT i2, la1, la4, vc3, i1, vc4 FROM GerosTestTable") or MaxDBTest::logerror("prepare SELECT failed $DBI::err $DBI::errstr");
$sth->execute() or MaxDBTest::logerror("execute SELECT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("bind_columns: bind too few columns -- should fail");
#$dbh->trace(10);
# we would have to bind 6 columns
eval {
  $sth->bind_columns(\$resdata[0], \$resdata[1], \$resdata[2], \$resdata[3], \$resdata[4]);
}; MaxDBTest::logerror("bind_col succeeded. Expected was fail") if (!$@);

$sth->{'PrintError'} = 1;
MaxDBTest::endTest();



MaxDBTest::beginTest("prepare and execute SELECT statement");
$sth = $dbh->prepare("SELECT la4, vc2, i1, i4, vc1 FROM GerosTestTable") or MaxDBTest::logerror("prepare SELECT failed $DBI::err $DBI::errstr");
$sth->execute() or MaxDBTest::logerror("execute SELECT failed $DBI::err $DBI::errstr");
MaxDBTest::endTest();

MaxDBTest::beginTest("bind_columns: bind too many columns -- should fail");
# we would have to bind 6 columns

eval {
  $sth->bind_columns(\$resdata[0], \$resdata[1], \$resdata[2], \$resdata[3], \$resdata[4], \$resdata[5]);
}; MaxDBTest::logerror("bind_col succeeded. Expected was fail") if (!$@);

$sth->{'PrintError'} = 1;
$sth->finish();
MaxDBTest::endTest();


# release

MaxDBTest::beginTest("drop table");
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

