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
   $tests = 6;
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
MaxDBTest::dropTable($c, "trailingzerobytes");
MaxDBTest::Test(1);

print " Test 3: create table\n";
$c->do("CREATE TABLE trailingzerobytes (ID INT NOT NULL, DTA LONG BYTE)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: insert data\n";
$c->{LongReadLen} = 50_000_000;
$c->do( 'INSERT INTO trailingzerobytes ( ID, DTA ) VALUES ( 1, ? )', undef, $data ) or die "INSERT INTO trailingzerobytes failed $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: select data\n";
my $s = $c->prepare( 'SELECT DTA FROM trailingzerobytes' ) or die "PREPARE SELECT FROM trailingzerobytes failed $DBI::err $DBI::errstr\n";
$s->execute or die "EXECUTE SELECT FROM ... failed $DBI::err $DBI::errstr\n"; 
my $row = $s->fetchrow_hashref() or die "FETCH SELECT FROM ... failed $DBI::err $DBI::errstr\n"; 
MaxDBTest::Test(1);

print " Test 6: check data\n";
MaxDBTest::Test((hexify( $data ) eq hexify($row->{DTA})));

print 'Inserted: ', length( $data ), ' bytes, ', hexify( $data ), "\n";
print 'Selected: ', length( $row->{DTA} ),' bytes, ', hexify( $row->{DTA} ), "\n";

sub hexify {
        return join( ' ',
                map { sprintf '%02x', ord( $_ ) } split //, shift
        );
}

