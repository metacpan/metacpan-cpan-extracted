#!perl -w -I./t
#/*!
#  @file           142UndefParameter.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          use several statement objects (almost) concurrently
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



# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
#my $dbh = DBI->connect("dbi:ODBC:HOMER") or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("Bind undef parameter for string/number output");

my $msg_version_number = undef;
my $dbs = $dbh->prepare("select 123456789 INTO ? FROM DUAL") or die "select 123456789 INTO ? FROM DUAL $DBI::err $DBI::errstr\n";
   $dbs->bind_param_inout(1, \$msg_version_number, 10) or die "bind undef value failed $DBI::err $DBI::errstr\n";;
	 $dbs->execute() or die "execute select 123456789 INTO ? FROM DUAL failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::Test(($msg_version_number==123456789)?1:0);

MaxDBTest::beginTest("Bind undef parameter for boolean output");

my $msg_version_number2 = undef;
   $dbs = $dbh->prepare("select TRUE INTO ? FROM DUAL") or die "select TRUE INTO ? FROM DUAL $DBI::err $DBI::errstr\n";
   $dbs->bind_param_inout(1, \$msg_version_number2, 10) or die "bind undef value failed $DBI::err $DBI::errstr\n";;
	 $dbs->execute() or die "execute select TRUE INTO ? FROM DUAL failed $DBI::err $DBI::errstr\n";
print "$msg_version_number2\n"; 
MaxDBTest::endTest();
MaxDBTest::Test(($msg_version_number2==1)?1:0);
	 