#!perl -w -I./t
#/*!
#  @file           133blobfetch.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          insert an fetch a lot of medium size LONG rows. use 'LongTruncOk' and 'LongReadLen'
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
   $tests = 17;
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

MaxDBTest::beginTest("create table with three columns (2x LONG ASCII, 1x INTEGER)");
$dbh->do("CREATE TABLE GerosTestTable (la1 LONG ASCII, i INTEGER, la2 LONG ASCII)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


# run

my ($data1, $data2) = ("_________1_________2_________3", "_________1_________2_________3_________4_________5");
my ($resdata1, $resdata2);

MaxDBTest::beginTest("insert one row (length of strings: 30, 50)");
MaxDBTest::execSQL($dbh, qq{INSERT INTO GerosTestTable (la1, i, la2) VALUES ('$data1', 1, '$data2')}) or MaxDBTest::logerror(qq{INSERT failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("LongReadLen := 60, (default: LongTruncOk = false)");
$dbh->{'LongReadLen'} = 60;
#$dbh->{'LongTruncOk'} = 0; # should be the default value
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: should succeed");
($resdata1, $resdata2) = $dbh->selectrow_array("SELECT la1, la2 FROM GerosTestTable WHERE i = 1");
if (($resdata1 ne $data1) or ($resdata2 ne $data2)) {
    MaxDBTest::logerror(qq{Wrong data returned: ('$resdata1', '$resdata2'). Expected was ('$data1', '$data2')});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("LongReadLen := 50");
$dbh->{'LongReadLen'} = 50;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: should succeed");
($resdata1, $resdata2) = $dbh->selectrow_array("SELECT la1, la2 FROM GerosTestTable WHERE i = 1");
if (($resdata1 ne $data1) or ($resdata2 ne $data2)) {
    MaxDBTest::logerror(qq{Wrong data returned: ('$resdata1', '$resdata2'). Expected was ('$data1', '$data2')});
}
MaxDBTest::endTest();

MaxDBTest::beginTest("LongReadLen := 40");
$dbh->{'LongReadLen'} = 40;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: should fail");
$dbh->{'PrintError'} = 0;
if ($dbh->selectrow_array("SELECT la1, la2 FROM GerosTestTable WHERE i = 1")) {
    MaxDBTest::logerror(qq{Select succeeded. Expected was fail});
}
$dbh->{'PrintError'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("LongTruncOk := true");
$dbh->{'LongTruncOk'} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare: (string, truncated string) should be returned");
my $expectedstr2 = substr($data2, 0, 40);
($resdata1, $resdata2) = $dbh->selectrow_array("SELECT la1, la2 FROM GerosTestTable WHERE i = 1");
if (($resdata1 ne $data1) or ($resdata2 ne $expectedstr2)) {
    MaxDBTest::logerror(qq{Wrong data returned: ('$resdata1', '$resdata2'). Expected was ('$data1', '$expectedstr2')});
}
MaxDBTest::endTest();

my @myarr = ([qw/a bc/], [qw/def ghi/], [qw/JKLM MNOPQ/], [qw/r STuv/], [qw/Wxyz hallo/], [qw/hallohallo gerostest/], [qw/toll jippie/],
             [qw/juchuuuhhh abbbccc/], [qw/b d524ef/], [qw/11ghi JKLM617/], [qw/M r2/], [qw/ST Wxyz1234567890/], [qw/hall hallhall/],
             [qw/gerostesttest toll!!/], [qw/jippie! juchuuuhhh!!!/]);

MaxDBTest::beginTest("insert a lot of rows (length of strings < 20)");
my $sth = $dbh->prepare("INSERT INTO GerosTestTable (la1, i, la2) VALUES (?, 2, ?)") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
foreach $ref (@myarr) {
    $sth->execute($$ref[0], $$ref[1]) or die "execute failed $DBI::err $DBI::errstr\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("LongReadLen := 50, LongTruncOk := false");
$dbh->{'LongReadLen'} = 50;
$dbh->{'LongTruncOk'} = 0;
MaxDBTest::endTest();

MaxDBTest::beginTest("fetch and compare all rows");
$sth = $dbh->prepare("SELECT la1, la2 FROM GerosTestTable WHERE i = 2") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
my $i=0;
while (($resdata1, $resdata2) = $sth->fetchrow_array()) {
    if (($resdata1 ne $myarr[$i][0]) || ($resdata2 ne $myarr[$i][1])) {
        MaxDBTest::logerror(qq{wrong data was returned: ($resdata1, '$myarr[$i][0]'). Expected was ($resdata2, '$myarr[$i][1]')});
    }
    $i++;
}
MaxDBTest::endTest();



# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

