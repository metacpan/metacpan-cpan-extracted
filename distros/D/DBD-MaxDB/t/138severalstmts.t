#!perl -w -I./t
#/*!
#  @file           138severalstmts.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          use several statement objects (almost) concurrently
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

my $n = 50;
my $m = 8;
my ($i, $j);


# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("create n tables with one column each (VARCHAR(40))");
for ($i=0; $i<$n; $i++) {
    $dbh->do(qq{CREATE TABLE GerosTestTable$i (la LONG ASCII)}) or
        MaxDBTest::logerror(qq{CREATE TABLE failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("insert m rows each");
for ($i=0; $i<$n; $i++) {
    my $insertsth = $dbh->prepare(qq{INSERT INTO GerosTestTable$i (la) VALUES (?)}) or
        MaxDBTest::logerror(qq{prepare INSERT failed $DBI::err $DBI::errstr});
    for ($j=0; $j<$m; $j++) {
        $insertsth->execute(qq{test string $i $j});
    }
}
MaxDBTest::endTest();


# run

# array with n entries
my @stmts;
$#stmts = ($n-1);

MaxDBTest::beginTest("prepare n SELECT statements");
for ($i=0; $i<$n; $i++) {
    $stmts[$i] = $dbh->prepare(qq{SELECT la FROM GerosTestTable$i}) or
        MaxDBTest::logerror(qq{prepare SELECT failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("execute them sequentially");
for ($i=0; $i<$n; $i++) {
    $stmts[$i]->execute() or
        MaxDBTest::logerror(qq{execute SELECT failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch the data sequentially");
for ($j=0; $j<$m; $j++) {
    for ($i=0; $i<$n; $i++) {
        my $res = $stmts[$i]->fetchrow_array() or
            MaxDBTest::logerror(qq{fetchrow_array failed $DBI::err $DBI::errstr});
        if ($res ne qq{test string $i $j}) {
            MaxDBTest::logerror(qq{wrong data returned: '$res'. Expected was 'test string $i $j'});
        }
    }
}
for ($i=0; $i<$n; $i++) {
    if ($stmts[$i]->fetchrow_array()) {
        MaxDBTest::logerror(qq{query $i returned more data than expected.});
    }
}
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop all the tables");
for ($i=0; $i<$n; $i++) {
    MaxDBTest::dropTable($dbh, qq{GerosTestTable$i}) or
        MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

