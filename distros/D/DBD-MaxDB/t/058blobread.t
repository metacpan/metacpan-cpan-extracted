#!perl -w -I./t
#/*!
#  @file           058blobread.t
#  @author         ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          tests blob_read command
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

# DBI->trace(2);

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 6;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $rc;

print "1..$tests\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
$dbh->{LongReadLen} = 0;
$dbh->{LongTruncOk} = 1;
MaxDBTest::Test(1);

print " Test 2: create table\n";
$dbh->{PrintError} = 0;
$dbh->do ("DROP TABLE BLOBTEST");
$dbh->{PrintError} = 1;
$rc = $dbh->do ("CREATE TABLE BLOBTEST (I INTEGER, L LONG ASCII, K LONG BYTE)");
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

print " Test 4: select from table\n";
my $sth2 = $dbh->prepare ("SELECT L,K FROM BLOBTEST WHERE I = 1");
$rc |= $sth2->execute ();
MaxDBTest::Test($rc);

$rc |= $sth2->fetch ();
for (my $p = 0; $p <= 1; $p++){
print " Test ".(5+$p).": read blob data\n";
my $data = "";
my $offset = 0;
my $chunk = "";
my $i = 0;
while ($chunk = $sth2->blob_read($p, $offset, length($long_gen))) {
  $i++;
  $offset += length($chunk);
  $data .= $chunk;
  if ($chunk ne $long_gen) {
    print "Error in blob_read. $i: $chunk\n";
  }
}
my $dlen = length($data);
if ($dlen ne length($long_description)) {
  print "Error in retrieved data length.\n";
}
print "data: $dlen\n";
MaxDBTest::Test($rc);
}

__END__

