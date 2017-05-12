#!perl -w -I./t
#/*!
#  @file           050connect.t
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          simple connect test
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
   $tests = 5;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";

MaxDBTest::Test(1);

print " Test 2: connecting to the database\n";
if (! defined $ENV{SERVERDB} || ! defined $ENV{SERVERNODE}) {
  MaxDBTest::Test("skipped", "SERVERDB/SERVERNODE is undefined");
} else {      
my $dbh = DBI->connect("DBI:MaxDB:$ENV{SERVERNODE}/$ENV{SERVERDB}","DBA","DBA") or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
}

print "3..$tests\n";
my $dbh = DBI->connect("$ENV{DBI_DSN}",$ENV{DBI_USER},$ENV{DBI_PASS}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: setting connect properties\n";
$dbh->{RaiseError} = 1;
$dbh->{LongReadLen} = 800;
MaxDBTest::Test(1);

print " Test 5: disconnecting from the database\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
