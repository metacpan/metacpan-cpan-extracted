#!perl -w -I./t
#/*!
#  @file           054stmtproperties.t
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          statement properties test
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
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
MaxDBTest::dropTable($dbh, "nestedselect");
MaxDBTest::Test(1);

print " Test 3: create table\n";
$dbh->do("CREATE TABLE nestedselect (K1 VARCHAR(3), PRIMARY KEY (K1))") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: drop table\n";
MaxDBTest::dropTable($dbh, "nestedselect1");
MaxDBTest::Test(1);

print " Test 5: create table\n";
$dbh->do("CREATE TABLE nestedselect1 ( K1 VARCHAR(3), K2 VARCHAR(3), PRIMARY KEY ( K1, K2 ))") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: insert data\n";
$dbh->do( "INSERT INTO nestedselect ( K1 ) VALUES ('001')" ) or die "INSERT INTO trailingzerobytes failed $DBI::err $DBI::errstr\n";
$dbh->do( "INSERT INTO nestedselect ( K1 ) VALUES ('002')" ) or die "INSERT INTO trailingzerobytes failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 7: insert data\n";
$dbh->do( "INSERT INTO nestedselect1 ( K1, K2 ) VALUES ('002','001')" ) or die "INSERT INTO trailingzerobytes failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "8..$tests\n";
my $sth1 = $dbh->prepare("Select k1 From nestedselect order by k1") or die "Can't prepare sth1 $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "9..$tests\n";
my $sth2 = $dbh->prepare("Select k2 From nestedselect1 Where k1 = ? order by k2") or die "Can't prepare sth2 $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "10..$tests\n";
$sth1->execute or die "Can't execute sth1 $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "11..$tests\n";
my ( $k1 ) = $sth1->fetchrow_array; 
MaxDBTest::Test(($k1 eq '001'));
  
print "12..$tests\n";
$sth2->execute( $k1 ) or die "Can't execute sth1 $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "13..$tests\n";
my ( $k2 ) = $sth2->fetchrow_array ;
MaxDBTest::Test((!defined $k2));
 
print "14..$tests\n";
( $k1 ) = $sth1->fetchrow_array; 
MaxDBTest::Test(($k1 eq '002'));
  
print "15..$tests\n";
$sth2->execute( $k1 ) or die "Can't execute sth1 $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print "16..$tests\n";
( $k2 ) = $sth2->fetchrow_array ;
MaxDBTest::Test(($k2 eq '001'));

print "17..$tests\n";
$sth1->finish;
$sth2->finish;
$dbh->disconnect;
MaxDBTest::Test(14);
