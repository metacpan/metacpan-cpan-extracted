#!perl -w -I./t
#/*!
#  @file           053do.t
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          tests the DBI do command
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
   $tests = 3;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

MaxDBTest::dropTable($dbh,'HOMER');

print " Test 2: check do command\n";
$rc = $dbh->do('create table homer (name char(30))') or die "Can't execute do(...)\n";
if ($rc eq '0E0'){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0);
}

print " Test 3: check do command\n";
$rc = $dbh->do("insert into homer values ('SIMPSON')") or die "Can't execute do(...)\n";
print "RC=$rc\n";
if ($rc == 1){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0);
}