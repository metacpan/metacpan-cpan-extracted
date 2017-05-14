#!perl -w -I./t
#/*!
#  @file           058blobread.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          tests blob_read command
#
#\if EMIT_LICENCE
#
#    ========== licence begin  GPL
#    Copyright (C) 2001-2007 SAP AG
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

# DBI->trace(2);

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 13;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $rc;

print "1..$tests\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
$dbh->{MAXDB_READ_LONG_COMPLETE} = 1;
$dbh->{LongReadLen} = 500000;
#$dbh->{LongTruncOk} = 1;
MaxDBTest::Test(1);

print " Test 2: create table\n";
$dbh->{PrintError} = 0;
$dbh->do ("DROP TABLE BLOBTEST");
$dbh->{PrintError} = 1;
$rc = $dbh->do ("CREATE TABLE BLOBTEST (I INTEGER KEY, L LONG ASCII, K LONG BYTE)");
MaxDBTest::Test($rc);

my $long_gen = "abcdefghijklmnopqrstuvwxyz";
my $long_description = $long_gen x 2000;

print " Test 3: insert into table\n";
my $sth1 = $dbh->prepare ("INSERT INTO BLOBTEST (I, L, K) VALUES (?, ?, ?)");
$rc |= $sth1->bind_param (1, 1);
$rc |= $sth1->bind_param (2, $long_description);
$rc |= $sth1->bind_param (3, $long_description);
$rc |= $sth1->execute ();
MaxDBTest::Test($rc);

print " Test 4: insert into table\n";
$rc |= $sth1->bind_param (1, 2);
$rc |= $sth1->bind_param (2, $long_description);
$rc |= $sth1->bind_param (3, $long_description);
$rc |= $sth1->execute ();
MaxDBTest::Test($rc);

print " Test 5: select from table\n";
my $sth2 = $dbh->prepare ("SELECT L,K FROM BLOBTEST");
$rc |= $sth2->execute ();
MaxDBTest::Test($rc);

print " Test 6: fetchall_arrayref\n";
my $rs = $sth2->fetchall_arrayref();
MaxDBTest::Test($rc);

my $tmp = 0;
foreach my $row (@$rs){
  my ($l,$k) = @$row;

	print " Test ".(5+($tmp++)).": read blob data\n";
  MaxDBTest::Test(($long_description eq $l));
  if ($long_description ne $l){
  	print "found ".$l." expected ".$long_description."\n";
  }
  
	print " Test ".(5+$tmp++).": check blob length\n";
  MaxDBTest::Test((length($long_description) eq length($k)), "found ".length($l)." expected ".length($long_description));
}

print " Test 11: select into from table\n";
my $sth3 = $dbh->prepare ("SELECT L,K INTO ?,? FROM BLOBTEST WHERE I = 1");
my $x = '';
my $y = '';
$sth3->bind_param_inout(1, \$x, 10);
$sth3->bind_param_inout(2, \$y, 10);
$rc |= $sth3->execute ();
MaxDBTest::Test($rc);

print " Test 12: read blob data\n";
MaxDBTest::Test(($long_description eq $x));
if ($long_description ne $x){
#	print "found ".$x." expected ".$long_description."\n";
}

print " Test 13: check blob length\n";
MaxDBTest::Test((length($long_description) eq length($x)), "found ".length($x)." expected ".length($long_description));


__END__

