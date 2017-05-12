#!perl -w -I./t
#/*!
#  @file           100connectproperties.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check connect with properties
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
   $tests = 42;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $dbh;

print "1..$tests\n";
print " Test 1: connect with empty property list\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: check if 'Active' is set\n";
MaxDBTest::Test($dbh->{"Active"});

print " Test 3: check if 'Kids' is set\n";
MaxDBTest::Test(defined $dbh->{'Kids'});

print " Test 4: check if 'ActiveKids' is set\n";
MaxDBTest::Test(defined $dbh->{'ActiveKids'});

print " Test 5: retrieve default value for 'Warn'\n";
my $Warndefault = $dbh->{'Warn'};
print " Default value for 'Warn' = $Warndefault\n";
MaxDBTest::Test(1);

print " Test 6: retrieve default value for 'CompatMode'\n";
my $CompatModedefault = $dbh->{'CompatMode'};
print " Default value for 'CompatMode' = $CompatModedefault\n";
MaxDBTest::Test(1);

print " Test 7: retrieve default value for 'InactiveDestroy'\n";
my $InactiveDestroydefault = $dbh->{'InactiveDestroy'};
print " Default value for 'InactiveDestroy' = $InactiveDestroydefault\n";
MaxDBTest::Test(1);

print " Test 8: retrieve default value for 'PrintError'\n";
my $PrintErrordefault = $dbh->{'PrintError'};
print " Default value for 'PrintError' = $PrintErrordefault\n";
MaxDBTest::Test(1);

print " Test 9: retrieve default value for 'RaiseError'\n";
my $RaiseErrordefault = $dbh->{'RaiseError'};
print " Default value for 'RaiseError' = $RaiseErrordefault\n";
MaxDBTest::Test(1);

print " Test 10: retrieve default value for 'ChopBlanks'\n";
my $ChopBlanksdefault = $dbh->{'ChopBlanks'};
print " Default value for 'ChopBlanks' = $ChopBlanksdefault\n";
MaxDBTest::Test(1);

print " Test 11: retrieve default value for 'LongReadLen'\n";
my $LongReadLendefault = $dbh->{'LongReadLen'};
print " Default value for 'LongReadLen' = $LongReadLendefault\n";
MaxDBTest::Test(1);

print " Test 12: retrieve default value for 'LongTruncOk'\n";
my $LongTruncOkdefault = $dbh->{'LongTruncOk'};
print " Default value for 'LongTruncOk' = $LongTruncOkdefault\n";
MaxDBTest::Test(1);

print " Test 13: retrieve default value for 'Taint'\n";
my $Taintdefault = $dbh->{'Taint'};
print " Default value for 'Taint' = $Taintdefault\n";
MaxDBTest::Test(1);

print " Test 14: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 15: connect with property 'Warn' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'Warn' => !$Warndefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 16: check if 'Warn' is set to expected value\n";
MaxDBTest::Test(($dbh->{'Warn'} == !$Warndefault));

print " Test 17: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 18: connect with property 'CompatMode' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'CompatMode' => !$CompatModedefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 19: check if 'CompatMode' is set to expected value\n";
MaxDBTest::Test(($dbh->{'CompatMode'} == !$CompatModedefault));

print " Test 20: check if 'Warn' is set to default value\n";
MaxDBTest::Test(($dbh->{'Warn'} == $Warndefault));

print " Test 21: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 22: connect with property 'InactiveDestroy' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'InactiveDestroy' => !$InactiveDestroydefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 23: check if 'InactiveDestroy' is set to expected value\n";
MaxDBTest::Test(($dbh->{'InactiveDestroy'} == !$InactiveDestroydefault));

print " Test 24: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 25: connect with property 'PrintError' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'PrintError' => !$PrintErrordefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 26: check if 'PrintError' is set to expected value\n";
MaxDBTest::Test(($dbh->{'PrintError'} == !$PrintErrordefault));

print " Test 27: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 28: connect with property 'RaiseError' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'RaiseError' => !$RaiseErrordefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 29: check if 'RaiseError' is set to expected value\n";
MaxDBTest::Test(($dbh->{'RaiseError'} == !$RaiseErrordefault));

print " Test 30: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 31: connect with property 'ChopBlanks' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'ChopBlanks' => !$ChopBlanksdefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 32: check if 'ChopBlanks' is set to expected value\n";
MaxDBTest::Test(($dbh->{'ChopBlanks'} == !$ChopBlanksdefault));

print " Test 33: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 34: connect with property 'LongReadLen' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'LongReadLen' => !$LongReadLendefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 35: check if 'LongReadLen' is set to expected value\n";
MaxDBTest::Test(($dbh->{'LongReadLen'} == !$LongReadLendefault));

print " Test 36: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 37: connect with property 'LongTruncOk' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'LongTruncOk' => !$LongTruncOkdefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 38: check if 'LongTruncOk' is set to expected value\n";
MaxDBTest::Test(($dbh->{'LongTruncOk'} == !$LongTruncOkdefault));

print " Test 39: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 40: connect with property 'Taint' = not(default)\n";
$dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {'Taint' => !$Taintdefault}) or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 41: check if 'Taint' is set to expected value\n";
MaxDBTest::Test(($dbh->{'Taint'} == !$Taintdefault));

print " Test 42: disconnect\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);


