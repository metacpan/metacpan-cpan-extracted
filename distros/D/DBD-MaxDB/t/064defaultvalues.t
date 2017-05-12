#!perl -w -I./t
#/*!
#  @file           062indexes.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          error message from open source
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

my $data = '1234abcd';

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 7;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}
print "1..$tests\n";
print " Test 1: connect\n";
my $c = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: drop table\n";
MaxDBTest::dropTable($c, "defaultvalues");
MaxDBTest::Test(1);

my $testval = "abc123"
my $testval_int = 42;

print " Test 3: create table\n";
$c->do("CREATE TABLE defaultvalues (ID INT NOT NULL DEFAULT ".$testval_int." , DTA VARCHAR(10) DEFAULT ".$testval.")") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: insert data\n";
my $s = $c->prepare( 'INSERT INTO defaultvalues ( ID, DTA ) VALUES ( ?, ? )' ) or die "PREPARE INSERT ... failed $DBI::err $DBI::errstr\n";
$s->execute or die "EXECUTE INSERT ... failed $DBI::err $DBI::errstr\n"; 
MaxDBTest::Test(1);

print " Test 5: select data\n";
my $s2 = $c->prepare( 'SELECT * FROM defaultvalues' ) or die "PREPARE SELECT ... failed $DBI::err $DBI::errstr\n";
$s2->execute or die "EXECUTE SELECT ... failed $DBI::err $DBI::errstr\n"; 
my $row = $s2->fetchrow_hashref() or die "FETCH ... failed $DBI::err $DBI::errstr\n"; 
MaxDBTest::Test(1);

print " Test 6: check data\n";
MaxDBTest::Test( $testval eq $row->{DTA}));

print " Test 7: check data\n";
MaxDBTest::Test($testval_int == $row->{ID});

$c->disconnect;

