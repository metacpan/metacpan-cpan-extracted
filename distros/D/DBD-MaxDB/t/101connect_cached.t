#!perl -w -I./t
#/*!
#  @file           101connect_cached.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check connect_chached
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

my $stored_dbh;
my $dbh;

print "1..$tests\n";
print " Test 1: connect using connect_cached. Store handle\n";
$dbh = DBI->connect_cached() or die "Can't connect $DBI::err $DBI::errstr\n";
$stored_dbh = $dbh;
MaxDBTest::Test(1);

print " Test 2: disconnect\n";
#$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 3: connect again using connect_chached\n";
$dbh = DBI->connect_cached() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: compare the retrieved handle with the one we stored earlier => they should be equal\n";
MaxDBTest::Test(($stored_dbh == $dbh));

print " Test 5: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 6: connect using connect_cached and connect properties set\n";
$dbh = DBI->connect_cached($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'PrintError' => 0}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 7: compare the retrieved handle with the one we stored earlier => they should be different\n";
MaxDBTest::Test(($stored_dbh != $dbh));

print " Test 8: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
