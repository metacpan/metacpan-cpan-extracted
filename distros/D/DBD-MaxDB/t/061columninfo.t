#!perl -w -I./t
#/*!
#  @file           061columninfo.t
#  @author         MarcoP
#  @ingroup        dbd::MaxDB
#  @brief          tests table_info command
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
   $tests = 9;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";

my $rc;

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop user perltest");
my $result = MaxDBTest::execSQL($dbh, qq{drop user perltest});
MaxDBTest::endTest();

MaxDBTest::beginTest("create user perltest");
$dbh->do("CREATE USER PERLTEST PASSWORD PERLTEST RESOURCE NOT EXCLUSIVE") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("connect");
$dbh = DBI->connect(undef, "PERLTEST","PERLTEST") or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("table info check empty schema");
my $tabsth = $dbh->column_info(undef,"PERLTEST",undef,undef);
my $rowarray = $tabsth->fetchall_arrayref();
#print "rowcnt $#$rowarray\n";
if ($#$rowarray != -1) {
    MaxDBTest::logerror(qq{empty resultset expected but max rowarray index is $#$rowarray});
}
MaxDBTest::endTest();

#MaxDBTest::beginTest("table info check wrong type");
#$tabsth = $dbh->table_info(undef,undef,undef,);
#$rowarray = $tabsth->fetchall_arrayref();
#
#if ($#$rowarray != -1) {
#    MaxDBTest::logerror(qq{empty resultset expected but max rowarray index is $#$rowarray});
#}
#MaxDBTest::endTest();
#
#MaxDBTest::beginTest("table info check table_info");
#$tabsth = $dbh->table_info();
#$rowarray = $tabsth->fetchall_arrayref();
##print "rowcnt $#$rowarray\n";
#if ($#$rowarray < 0) {
#    MaxDBTest::logerror(qq{empty resultset expected but max rowarray index is $#$rowarray});
#}
#MaxDBTest::endTest();

my $tabname = "ErwinLottemann";
for ($i=1; $i<=1; $i++){
	MaxDBTest::beginTest("create table $tabname$i");
	$dbh->do("CREATE TABLE $tabname$i (erwin INTEGER, lottemann INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
	MaxDBTest::endTest();
}
#for ($i=1; $i<=5; $i++){
#	MaxDBTest::beginTest("create view ".$tabname.$i."VIEW");
#	$dbh->do("CREATE VIEW ".$tabname.$i."VIEW AS SELECT * FROM $tabname$i") or die "CREATE VIEW failed $DBI::err $DBI::errstr\n";
#	MaxDBTest::endTest();
#}

#
#MaxDBTest::beginTest("table info check type TABLE");
#$tabsth = $dbh->table_info(undef,"PERLTEST",undef,"TABLE");
#$rowarray = $tabsth->fetchall_arrayref();
##print "rowcnt $#$rowarray\n";
#if ($#$rowarray != 6) {
#    MaxDBTest::logerror(qq{rowarry index 6 expected found $#$rowarray});
#}
#MaxDBTest::endTest();
#
#MaxDBTest::beginTest("table info check type VIEW");
#$tabsth = $dbh->table_info(undef,"PERLTEST",undef,"VIEW");
#$rowarray = $tabsth->fetchall_arrayref();
##print "rowcnt $#$rowarray\n";
#if ($#$rowarray != 4) {
#    MaxDBTest::logerror(qq{rowarry index 4 expected found $#$rowarray});
#}
#MaxDBTest::endTest();
#
#MaxDBTest::beginTest("table info check type VIEW,TABLE");
#$tabsth = $dbh->table_info(undef,"PERLTEST",undef,"VIEW,TABLE");
#$rowarray = $tabsth->fetchall_arrayref();
##print "rowcnt $#$rowarray\n";
##print "STMT: $tabsth->{Statement}\n";
#if ($#$rowarray != 11) {
#    MaxDBTest::logerror(qq{rowarry index 11 expected found $#$rowarray});
#}
#MaxDBTest::endTest();
#
#MaxDBTest::beginTest("table info check table using search pattern");
#$tabsth = $dbh->table_info(undef,"PERLTEST","ERWINLOTTEMANN1%","VIEW,TABLE");
#$rowarray = $tabsth->fetchall_arrayref();
##print "rowcnt $#$rowarray\n";
##print "STMT: $tabsth->{Statement}\n";
#if ($#$rowarray != 1) {
#    MaxDBTest::logerror(qq{rowarry index 1 expected found $#$rowarray});
#}
#MaxDBTest::endTest();
#

MaxDBTest::beginTest("tables");
$tabsth = $dbh->column_info(undef,"PERLTEST",undef,undef);
my $rowcnt = 0;
#print 
while ( my ( $TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$DATA_TYPE,$TYPE_NAME,$COLUMN_SIZE,$BUFFER_LENGTH,$DECIMAL_DIGITS,$NUM_PREC_RADIX,$NULLABLE,$REMARKS,$COLUMN_DEF,$SQL_DATA_TYPE,$SQL_DATETIME_SUB,$CHAR_OCTET_LENGTH,$ORDINAL_POSITION,$IS_NULLABLE ) = $tabsth->fetchrow_array() ) {
  foreach ($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$DATA_TYPE,$TYPE_NAME,$COLUMN_SIZE,$BUFFER_LENGTH,$DECIMAL_DIGITS,$NUM_PREC_RADIX,$NULLABLE,$REMARKS,$COLUMN_DEF,$SQL_DATA_TYPE,$SQL_DATETIME_SUB,$CHAR_OCTET_LENGTH,$ORDINAL_POSITION,$IS_NULLABLE) {
    $_ = "N/A" unless defined $_;
  }

  $rowcnt++;
  print "$TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$DATA_TYPE,$TYPE_NAME,$COLUMN_SIZE,$BUFFER_LENGTH,$DECIMAL_DIGITS,$NUM_PREC_RADIX,$NULLABLE,$REMARKS,$COLUMN_DEF,$SQL_DATA_TYPE,$SQL_DATETIME_SUB,$CHAR_OCTET_LENGTH,$ORDINAL_POSITION,$IS_NULLABLE\n";
}
print "rowcnt: $rowcnt\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

__END__
