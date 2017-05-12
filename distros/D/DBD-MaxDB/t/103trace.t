#!perl -w -I./t
#/*!
#  @file           103trace.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check trace and trace_msg
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
print " Test 1: call trace with trace_level = 0\n";
DBI->trace(0);
MaxDBTest::Test(1);

print " Test 2: call trace_msg => should fail\n";
MaxDBTest::Test(1);

print " Test 3: call trace with trace_level = 5\n";
MaxDBTest::Test(1);

print " Test 4: call trace_msg => should succeed\n";
MaxDBTest::Test(1);

print " Test 5: call trace_msg with min_level = 8 => should fail\n";
MaxDBTest::Test(1);


