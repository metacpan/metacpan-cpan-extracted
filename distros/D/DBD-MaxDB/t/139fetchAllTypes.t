#!perl -w -I./t
#/*!
#  @file           120fetchrow_array.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          check fetchrow_array
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
   $tests = 26;
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
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "fetchAllTypes");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table with two columns (INTEGER, VARCHAR(40))");
$dbh->do("CREATE TABLE fetchAllTypes ("
        ."  C_CHARASCII    Char (1) ASCII NOT NULL,"
        ."  C_CHARBYTE     Char (1) BYTE,"
        ."  C_VARCHARASCII  Varchar (1) ASCII,"
        ."  C_VARCHARBYTE   Varchar (1) BYTE,"
        ."  C_INT          Integer,"
        ."  C_SMALINT      Smallint,"
        ."  C_FLOAT        Float (5),"
        ."  C_FIXED        Fixed (5),"
        ."  C_FIXED1       Fixed (5,5),"
        ."  C_BOOLEAN      Boolean,"
        ."  C_DATE         Date,"
        ."  C_TIME         Time,"
        ."  C_TIMESTAMP    Timestamp,"
        ."  C_LONGASCII    Long ASCII,"
        ."  C_LONGBYTE     Long BYTE"
        .")",
        ) or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";

MaxDBTest::endTest();
# strings to be inserted

MaxDBTest::beginTest("insert ten rows");
$dbh->do("INSERT INTO fetchAllTypes VALUES ("
        ." 'A',"
        ."  x'01',"
        ."  'B',"
        ."  x'02',"
        ."  42,"
        ."  42,"
        ."  42.42,"
        ."  42,"
        ."  0.12345,"
        ."  TRUE,"
        ."  '1973-06-07',"
        ."  '14:30:08',"
        ."  '1999-01-23 14:30:08.456234',"
        ."  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',"
        ."  null"
        .")"
       ) or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

# run
MaxDBTest::beginTest("prepare SELECT statement");
$sth = $dbh->prepare("SELECT * FROM fetchAllTypes") or die "prepare INSERT failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("execute statement");
$sth->execute() or die "execute failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("fetchrow_array and compare (do not fetch all of the data)");
my $row = $sth->fetchrow_hashref() or MaxDBTest::logerror(qq{fetchrow_array failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

$rows = {"C_CHARASCII"=>"A", 
         "C_CHARBYTE"=>pack("sX",01), 
         "C_VARCHARASCII"=>'B', 
         "C_VARCHARBYTE"=>pack("sX",02), 
         "C_INT"=>42, 
         "C_SMALINT"=>42, 
         "C_FLOAT"=>42.42, 
         "C_FIXED"=>42, 
         "C_FIXED1"=>0.12345, 
         "C_BOOLEAN"=>"1", 
         "C_DATE"=>"1973-06-07", 
         "C_TIME"=>"14:30:08", 
         "C_TIMESTAMP"=>"1999-01-23 14:30:08.456234", 
         "C_LONGASCII"=>"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 
         "C_LONGBYTE"=>undef
        };

foreach $col (keys %$row){
MaxDBTest::beginTest("Check result for column $col");
  my $found = (defined $row->{$col})? $row->{$col}:"undef";  
  my $expected = (defined $rows->{$col})? $rows->{$col}:"undef";  
  if ($found ne $expected){
    print "Error difference in result Colname $col Value found >$found< expected >$expected<\n";    
  }
MaxDBTest::endTest();
}    

#MaxDBTest::beginTest("check result ");
#
#print "erg: ".$int." ".$bool."\n";   
#if (($int != 1) || ($bool != 1)) {
#    MaxDBTest::logerror(qq{wrong data was returned: ($int, $bool). Expected was (1, 1)});
#}
#MaxDBTest::endTest();

MaxDBTest::beginTest("call finish");
$sth->finish() or MaxDBTest::logerror(qq{finish failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("check if fetchrow_array fails");
$sth->{'PrintError'} = 0;
if ($sth->fetchrow_array()) {
    MaxDBTest::logerror(qq{fetchrow_array succeeded. Expected was fail});
}
$sth->{'PrintError'} = 1;
MaxDBTest::endTest();

# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "fetchAllTypes") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

