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
   $tests = 14;
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
$sth = $dbh->prepare("Select 'Homer' as father, 'Bart' as son from dual") or die "Can't prepare statement $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 3: check execute statement\n";
$sth->execute() or die "Can't execute statement $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 4: check NUM_OF_FIELDS option\n";
$cname = $sth->{"NUM_OF_FIELDS"};
print "$cname\n";
MaxDBTest::Test($cname);

print " Test 5: check NUM_OF_PARAMS option\n";
$cname = $sth->{"NUM_OF_PARAMS"};
print "$cname\n";
MaxDBTest::Test(! $cname);

print " Test 6: check NAME option\n";
$cname = $sth->{"NAME"};
$res = 0;
foreach $cd(@{$cname}){
  print "$cd\n";
  if ($cd eq "FATHER"){
    $res++;
  }elsif ($cd eq "SON"){
    $res++;
  }else{
    $res--;
  }
}
print "res: $res\n";
MaxDBTest::Test(($res==2)?1:0);

print " Test 7: check TYPE option\n";
$cname = $sth->{"TYPE"};
$res = 0;
foreach $cd(@{$cname}){
  print "$cd\n";
  if ($cd == 1){
    $res++;
  }elsif ($cd == -8 && $dbh->{"MAXDB_UNICODE"}){
    $res++;
  }else{
    $res--;
  }
}
print "res: $res\n";
MaxDBTest::Test(($res==2)?1:0);

print " Test 8: check PRECISION option\n";
$cname = $sth->{"PRECISION"};
$res = 0;
foreach $cd(@{$cname}){
  print "$cd\n";
  if ($cd == 5){
    $res++;
  }elsif ($cd == 4){
    $res++;
  } else{
    $res--;
  }
}
print "res: $res\n";
MaxDBTest::Test(($res==2)?1:0);

print " Test 9: check SCALE option\n";
$cname = $sth->{"SCALE"};
$res = 0;
foreach $cd(@{$cname}){
  if (! defined $cd){
    $res++;
    print "undef\n";
  } else{
    print "$cd\n";
    $res--;
  }
}
print "res: $res\n";
MaxDBTest::Test(($res==2)?1:0);

print " Test 10: check NULLABLE option\n";
$cname = $sth->{"NULLABLE"};
$res = 0;
foreach $cd(@{$cname}){
print "cd: $cd\n" ;
  if ($cd ==0 ){
    $res++;
  } else{
    $res--;
  }
}
print "res: $res\n";
MaxDBTest::Test(($res==2)?1:0);

print " Test 11: check CursorName option\n";
$cname = $sth->{"CursorName"};
print "$cname\n";
MaxDBTest::Test( $cname);

print " Test 12: check Statement option\n";
$cname = $sth->{"Statement"};
print "$cname\n";
MaxDBTest::Test( $cname);

print " Test 13: check RowsInCache option\n";
$cname = $sth->{"RowsInCache"};
MaxDBTest::Test((!defined $cd)?1:0);

$sth->finish();

print " Test 14: disconnecting\n";
$dbh->disconnect or die "Can't disconnect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);
