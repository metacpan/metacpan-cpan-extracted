#!perl -w -I./t
#/*!
#  @file           051properties.t
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          connect properties test
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
my $dbh = DBI->connect("$ENV{DBI_DSN}?sqlmode=oracle&timeout=0&autocommit=FALSE",$ENV{DBI_USER},$ENV{DBI_PASS}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: check AUTOCOMMIT option\n";
$rc = $dbh->{"AUTOCOMMIT"};
print "$rc\n";
MaxDBTest::Test($rc);

print " Test 3: check MAXDB_ISOLATIONLEVEL option\n";
MaxDBTest::Test($dbh->{"MAXDB_ISOLATIONLEVEL"});

print " Test 4: check MAXDB_KERNELVERSION option\n";
MaxDBTest::Test($dbh->{"MAXDB_KERNELVERSION"});

print " Test 5: check MAXDB_SDKVERSION option\n";
MaxDBTest::Test($dbh->{"MAXDB_SDKVERSION"});

print " Test 6: check MAXDB_LIBRARYVERSION option\n";
MaxDBTest::Test($dbh->{"MAXDB_LIBRARYVERSION"});

print " Test 7: check MAXDB_UNICODE option\n";
$rc = $dbh->{"MAXDB_UNICODE"};
MaxDBTest::Test(1);

print " Test 8: disconnecting\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
