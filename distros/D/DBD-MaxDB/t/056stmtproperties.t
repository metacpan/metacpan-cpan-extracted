#!perl -w -I./t
#/*!
#  @file           054stmtproperties.t
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          statement properties test
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
   $tests = 28;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: check prepare statement\n";
$sth = $dbh->prepare("Select 'Homer' as father, 'Bart' as sun from dual") or die "Can't prepare statement $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 3: check CURSORNAME option\n";
$cname = $sth->{"CURSORNAME"};
print "$cname\n";
MaxDBTest::Test($cname);

print " Test 4: check MAXDB_FETCHSIZE option\n";
$res = $sth->{"MAXDB_FETCHSIZE"};
if (! defined $res){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test($sth->{"MAXDB_FETCHSIZE"});
}

print " Test 5: check MAXDB_MAXROWS option\n";
MaxDBTest::Test(($sth->{"MAXDB_MAXROWS"}==0)?1:$sth->{"MAXDB_MAXROWS"});

print " Test 6: check MAXDB_RESULTSETCONCURRENCY option\n";
MaxDBTest::Test($sth->{"MAXDB_RESULTSETCONCURRENCY"});

print " Test 7: check MAXDB_RESULTSETTYPE option\n";
MaxDBTest::Test($sth->{"MAXDB_RESULTSETTYPE"});

print " Test 8: check MAXDB_ROWSAFFECTED option\n";
MaxDBTest::Test($sth->{"MAXDB_ROWSAFFECTED"});

print " Test 9: check MAXDB_ROWSETSIZE option\n";
if (! defined $sth->{"MAXDB_ROWSETSIZE"}){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test($sth->{"MAXDB_ROWSETSIZE"});
}

print " Test 10: check MAXDB_TABLENAME option\n";
if (! defined $sth->{"MAXDB_TABLENAME"}){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test($sth->{"MAXDB_TABLENAME"});
}

print " Test 11: check set CURSORNAME option\n";
$sth->{"CURSORNAME"}="SIMPSON";
MaxDBTest::Test(1);
print " Test 12: check modified CURSORNAME option\n";
$cname = $sth->{"CURSORNAME"};
print "$cname\n";
if ($cname eq "SIMPSON"){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong cursor name $cname\n");
}

print " Test 13: check MAXDB_FETCHSIZE option\n";
$sth->{"MAXDB_FETCHSIZE"}=10;
MaxDBTest::Test(1);
print " Test 14: check modified MAXDB_FETCHSIZE option\n";
if ($sth->{"MAXDB_FETCHSIZE"}==10){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong fetchsize $sth->{'MAXDB_FETCHSIZE'}\n");
}

print " Test 15: check MAXDB_MAXROWS option\n";
$sth->{"MAXDB_MAXROWS"}=10;
MaxDBTest::Test(1);
print " Test 16: check modified MAXDB_MAXROWS option\n";
if ($sth->{"MAXDB_MAXROWS"}==10){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong fetchsize $sth->{'MAXDB_MAXROWS'}\n");
}

print " Test 17: check MAXDB_ROWSAFFECTED option\n";
$sth = $dbh->prepare("create table TEMP.HOMER (a int)");
$sth->execute();
MaxDBTest::Test(1);
print " Test 18: check modified MAXDB_ROWSAFFECTED option\n";
if ($sth->{"MAXDB_ROWSAFFECTED"}==0){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong rowcount $sth->{'MAXDB_ROWSAFFECTED'}\n");
}

print " Test 19: check MAXDB_ROWSETSIZE option\n";
$sth->{"MAXDB_ROWSETSIZE"}=10;
MaxDBTest::Test(1);
print " Test 20: check modified MAXDB_ROWSETSIZE option\n";
if ($sth->{"MAXDB_ROWSETSIZE"}==10){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong MAXDB_ROWSETSIZE $sth->{'ROWSETSIZE'}\n");
}

print " Test 21: check MAXDB_TABLENAME option\n";
$sth = $dbh->prepare("select * from TEMP.HOMER for update of a\n");
$sth->execute() or die "Can't execute statement $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
print " Test 22: check MAXDB_TABLENAME option\n";
print "tablename $sth->{'MAXDB_TABLENAME'}\n";
if ($sth->{"MAXDB_TABLENAME"}eq '"TEMP"."HOMER"'){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "Wrong tablename $sth->{'MAXDB_TABLENAME'}\n");
}

print " Test 23: check MAXDB_RESULTSETCONCURRENCY option\n";
$sth = $dbh->prepare("select * from dual\n");
print "$sth->{'MAXDB_RESULTSETCONCURRENCY'}\n";
if ($sth->{"MAXDB_RESULTSETCONCURRENCY"}eq 'CONCUR_READ_ONLY'){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "MAXDB_RESULTSETCONCURRENCY should be CONCUR_READ_ONLY\n");
}
print " Test 24: setting MAXDB_RESULTSETCONCURRENCY option\n";
$sth->{'MAXDB_RESULTSETCONCURRENCY'}='CONCUR_UPDATABLE';
MaxDBTest::Test(1);



my $scrollableProp = (MaxDBTest::checkMinimalKernelVersion($dbh,"7.6"))?"FORWARD_ONLY":"SCROLL_SENSITIVE";

print " Test 25: check MAXDB_RESULTSETTYPE option\n";
$sth = $dbh->prepare("select * from dual\n");
print "$sth->{'MAXDB_RESULTSETTYPE'}\n";
if ($sth->{"MAXDB_RESULTSETTYPE"}eq $scrollableProp){
  MaxDBTest::Test(1);
} else {
  MaxDBTest::Test(0, "MAXDB_RESULTSETTYPE should be SCROLL_SENSITIVE\n");
}


print " Test 26: setting MAXDB_RESULTSETTYPE option\n";
$sth->{'MAXDB_RESULTSETTYPE'}='SCROLL_INSENSITIVE';
MaxDBTest::Test(1);

print " Test 27: setting MAXDB_RESULTSETCONCURRENCY option\n";
#$sth->cancel;
MaxDBTest::Test(1);


print " Test 28: disconnecting\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
