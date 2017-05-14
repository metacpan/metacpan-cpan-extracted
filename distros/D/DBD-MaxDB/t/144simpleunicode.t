#!perl -w -I./t
#/*!
#  @file           144simpleunicode.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          simple unicode test
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
   $tests = 42;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}
print "1..$tests\n";

MaxDBTest::beginTest("primary connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

my $unicodesupport = $dbh->{"MAXDB_UNICODE"};
my $username;
if ($unicodesupport) {
  $username = eval q{ "äü\x{8f6f}\x{4ef6}\x{5f00}\x{53d1}\x{5546}\x{662f}\x{82f1}\x{96c4}" };
  $username = "\"".$username."\""; 
  $password = eval q{ "äüö" }; 
#  $password = eval q{ "\x{8f6f}\x{4ef6}\x{5f00}" }; 
  $password = "\"".$password."\""; 
} else {
  $username = "abc123";
  $password = "abc123";
}
#print "username $username\n" if $unicodesupport;

MaxDBTest::beginTest("drop/create user\n");
$dbh->do(qq{DROP USER $username});
$dbh->do(qq{CREATE USER $username PASSWORD $password DBA NOT EXCLUSIVE}) or die "CREATE USER failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("connect with unicode user\n");
$dbh = DBI->connect($ENV{DBI_DSN}, $username, $password, {}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table\n");
MaxDBTest::dropTable($dbh, $username);
MaxDBTest::endTest();

MaxDBTest::beginTest("create table (two integer columns)\n");
my $cmd = "CREATE TABLE ".$username." ("
	."C_CHARASCII          Char (10) ASCII,"
	."C_CHARBYTE           Char (6) BYTE,";
if ($unicodesupport) {
	$cmd.= "C_CHARUNICODE        Char (10) UNICODE,";
} else {
	$cmd.="C_CHARUNICODE        Char (10),";
}
	$cmd.="C_VARCHARASCII       Varchar (10) ASCII,"
	."C_VARCHARBYTE        Varchar (10) BYTE,";
if ($unicodesupport) {
	$cmd.="C_VARCHARUNICODE     Varchar (10) UNICODE,";
}else{
	$cmd.="C_VARCHARUNICODE     Varchar (10),";
}
	$cmd.="C_LONGASCII          Long ASCII,"
	."C_LONGBYTE           Long BYTE";
if ($unicodesupport) {
	$cmd.=",C_LONGUNICODE        Long UNICODE" ;
}else{
	$cmd.=",C_LONGUNICODE        Long";
}
	$cmd.=")" ;
$dbh->do($cmd);
MaxDBTest::endTest();

my $stringAscii = eval q{ "äüöabc123" };
my $stringByte = eval q{ "abc123" };
my $stringutf8;

if ($unicodesupport) {
  $stringutf8 = eval q{ "\x{8f6f}\x{4ef6}\x{5f00}\x{53d1}\x{5546}\x{662f}\x{82f1}\x{96c4}" };
}else{
  $stringutf8 = eval q{ "äüöß" };
}
MaxDBTest::beginTest("insert one row");
$sth = $dbh->prepare("INSERT INTO ".$username." VALUES (?,?,?,?,?,?,?,?,?)") or die "INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("bind parameters with valid index");
$sth->bind_param(1, $stringAscii) or die "bind_param failed (column 1) $DBI::err $DBI::errstr";
$sth->bind_param(2, $stringByte)  or die "bind_param failed (column 2) $DBI::err $DBI::errstr";
$sth->bind_param(3, $stringutf8)  or die "bind_param failed (column 3) $DBI::err $DBI::errstr";

$sth->bind_param(4, $stringAscii) or die "bind_param failed (column 4) $DBI::err $DBI::errstr";
$sth->bind_param(5, $stringByte)  or die "bind_param failed (column 5) $DBI::err $DBI::errstr";
$sth->bind_param(6, $stringutf8)  or die "bind_param failed (column 6) $DBI::err $DBI::errstr";

$sth->bind_param(7, $stringAscii) or die "bind_param failed (column 7) $DBI::err $DBI::errstr";
$sth->bind_param(8, $stringByte)  or die "bind_param failed (column 8) $DBI::err $DBI::errstr";
$sth->bind_param(9, $stringutf8)  or die "bind_param failed (column 9) $DBI::err $DBI::errstr";
MaxDBTest::endTest();

MaxDBTest::beginTest("execute insert");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("call selectrow_array (list context) => returned array should have at least 1 entry\n");
my @row = $dbh->selectrow_array("SELECT * FROM ".$username) or die "selectrow_array failed $DBI::err $DBI::errstr";
if ($#row < 1) { die "selectrow_array returned array with less than 2 entries"; }
MaxDBTest::endTest();

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 1 found $row[0] expected $stringAscii\n");
MaxDBTest::TestEnd($row[0] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 2 found $row[1] expected $stringByte\n");
MaxDBTest::TestEnd($row[1] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 3 found $row[2] expected $stringutf8\n");
MaxDBTest::TestEnd($row[2] eq $stringutf8);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 4 found $row[3] expected $stringAscii\n");
MaxDBTest::TestEnd($row[3] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 5 found $row[4] expected $stringByte\n");
MaxDBTest::TestEnd($row[4] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 6 found $row[5] expected $stringutf8\n");
MaxDBTest::TestEnd($row[5] eq $stringutf8);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 7 found $row[6] expected $stringAscii\n");
MaxDBTest::TestEnd($row[6] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 8 found $row[7] expected $stringByte\n");
MaxDBTest::TestEnd($row[7] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 9 found $row[8] expected $stringutf8\n");
MaxDBTest::TestEnd($row[8] eq $stringutf8);

MaxDBTest::beginTest("call selectrow_array with bind_values set (list context)\n");
@row = $dbh->selectrow_array("SELECT * FROM ".$username." WHERE C_VARCHARUNICODE = ?", undef, $stringutf8) or die "selectrow_array failed $DBI::err $DBI::errstr";
MaxDBTest::TestEnd(($#row == 8));

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 1 found $row[0] expected $stringAscii\n");
MaxDBTest::TestEnd($row[0] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 2 found $row[1] expected $stringByte\n");
MaxDBTest::TestEnd($row[1] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 3 found $row[2] expected $stringutf8\n");
MaxDBTest::TestEnd($row[2] eq $stringutf8);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 4 found $row[3] expected $stringAscii\n");
MaxDBTest::TestEnd($row[3] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 5 found $row[4] expected $stringByte\n");
MaxDBTest::TestEnd($row[4] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 6 found $row[5] expected $stringutf8\n");
MaxDBTest::TestEnd($row[5] eq $stringutf8);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 7 found $row[6] expected $stringAscii\n");
MaxDBTest::TestEnd($row[6] eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 8 found $row[7] expected $stringByte\n");
MaxDBTest::TestEnd($row[7] eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 9 found $row[8] expected $stringutf8\n");
MaxDBTest::TestEnd($row[8] eq $stringutf8);

MaxDBTest::beginTest("call select into with bind_values\n");
my $out1 = undef;
my $out2 = undef;
my $out3 = undef;
my $out4 = undef;
my $out5 = undef;
my $out6 = undef;
my $out7 = undef;
my $out8 = undef;
my $out9 = undef;
my $sth1 = $dbh->prepare("SELECT * INTO ?,?,?,?,?,?,?,?,? FROM ".$username) or die "PREPARE select into failed $DBI::err $DBI::errstr";
MaxDBTest::endTest();

MaxDBTest::beginTest("bind output values\n");
	$sth1->bind_param_inout(1, \$out1, 10);
	$sth1->bind_param_inout(2, \$out2, 10);
	$sth1->bind_param_inout(3, \$out3, 10);
	$sth1->bind_param_inout(4, \$out4, 10);
	$sth1->bind_param_inout(5, \$out5, 10);
	$sth1->bind_param_inout(6, \$out6, 10);
	$sth1->bind_param_inout(7, \$out7, 10);
	$sth1->bind_param_inout(8, \$out8, 10);
	$sth1->bind_param_inout(9, \$out9, 10);
MaxDBTest::endTest();

MaxDBTest::beginTest("bind output values\n");
my $rv = $sth1->execute()or die "EXECUTE select into failed $DBI::err $DBI::errstr";
MaxDBTest::endTest();

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 1 found $out1 expected $stringAscii\n");
MaxDBTest::TestEnd($out1 eq $stringAscii);

MaxDBTest::beginTest(" compare the fetched data with the stuff we inserted for column 2 found $out2 expected $stringByte\n");
MaxDBTest::TestEnd($out2 eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 3 found $out3 expected $stringutf8\n");
MaxDBTest::TestEnd($out3 eq $stringutf8);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 4 found $out4 expected $stringAscii\n");
MaxDBTest::TestEnd($out4 eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 5 found $out5 expected $stringByte\n");
MaxDBTest::TestEnd($out5 eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 6 found $out6 expected $stringutf8\n");
MaxDBTest::TestEnd($out6 eq $stringutf8);	

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 7 found $out7 expected $stringAscii\n");
MaxDBTest::TestEnd($out7 eq $stringAscii);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 8 found $out8 expected $stringByte\n");
MaxDBTest::TestEnd($out8 eq $stringByte);

MaxDBTest::beginTest("compare the fetched data with the stuff we inserted for column 9 found $out9 expected $stringutf8\n");
MaxDBTest::TestEnd($out9 eq $stringutf8);

MaxDBTest::beginTest("drop table\n");
$dbh->do("DROP TABLE ".$username) or die "DROP TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect\n");
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


