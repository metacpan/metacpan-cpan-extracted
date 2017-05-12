#!perl -w -I./t
#/*!
#  @file           102driverdatasource.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check if MaxDB driver is listed and the specified database is available
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
   $tests = 4;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
print " Test 1: get available drivers list\n";
my @drivers = DBI->available_drivers() or die "Can't get driver list\n";
MaxDBTest::Test(1);

print " Test 2: check if MaxDB driver is available\n";
my $FoundMaxDB = 0;
foreach $driver (@drivers) {
    if ($driver eq "MaxDB") { $FoundMaxDB = 1; }
}
# if the MaxDB driver is not available we must not go on...
if (!$FoundMaxDB) { die "MaxDB driver is not available"; }
MaxDBTest::Test(1);

print " Test 3: get data sources list\n";
my @datasources = DBI->data_sources("MaxDB");
MaxDBTest::Test(1);

print " Test 4: check if there are there any data bases\n";
my $numDBs = $#datasources + 1;
print " Number of MaxDB data bases: $numDBs\n";
if ($numDBs < 1) {
    die "No data bases are available for MaxDB";
}

my $ds_found = 0;
foreach $ds (@datasources) {
    print "  ".$ds."\n"; 
    if ($ds=~ /^dbi:MaxDB:.*/) { $ds_found = 1; }
}
if (!$ds_found) { die "at least the datasource \"/dbi:MaxDB:v75/\" should be found"; }
MaxDBTest::Test(1);


