#!perl -w -I./t
#/*!
#  @file           110prepare_cached.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check prepare_cached
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
   $tests = 10;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $sth;
my $storedhandle;

print "1..$tests\n";
print " Test 1: connect\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
print " table GerosTestTable should not exist but let's drop it anyway\n";
$dbh->{'PrintError'} = 0;
$dbh->do("DROP TABLE GerosTestTable");
$dbh->{'PrintError'} = 1;
MaxDBTest::Test(1);

print " Test 3: create table with one column\n";
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: prepare statement using prepare_cached. store handle\n";
$sth = $dbh->prepare_cached("INSERT INTO GerosTestTable (i) VALUES (?)") or die "prepare failed $DBI::err $DBI::errstr\n";
$storedhandle = $sth;
MaxDBTest::Test(1);

print " Test 5: prepare the same statement once again\n";
$sth = 0;
$sth = $dbh->prepare_cached("INSERT INTO GerosTestTable (i) VALUES (?)") or die "prepare failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: compare the retrieved statement with the one we stored earlier. They should be equal\n";
MaxDBTest::Test(($sth == $storedhandle));

print " Test 7: prepare an other statement\n";
$sth = 0;
$sth = $dbh->prepare_cached("SELECT * FROM GerosTestTable WHERE i > ?") or die "prepare failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 8: compare the retrieved statement with the one we stored earlier. They should be different\n";
MaxDBTest::Test(($sth != $storedhandle));

print " Test 9: drop table\n";
$dbh->do("DROP TABLE GerosTestTable");
MaxDBTest::Test(1);

print " Test 10: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


