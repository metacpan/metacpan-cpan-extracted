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
my $tabsth = $dbh->primary_key_info(undef,"PERLTEST",undef);
my $rowarray = $tabsth->fetchall_arrayref();
#print "rowcnt $#$rowarray\n";
if ($#$rowarray != -1) {
    MaxDBTest::logerror(qq{empty resultset expected but max rowarray index is $#$rowarray});
}
MaxDBTest::endTest();

my $tabname = "ErwinLottemann";
for ($i=1; $i<=1; $i++){
	MaxDBTest::beginTest("create table $tabname$i");
	$dbh->do("CREATE TABLE $tabname$i (erwin INTEGER key, lottemann INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
	MaxDBTest::endTest();
}

MaxDBTest::beginTest("tables");
$tabsth = $dbh->primary_key_info(undef,"PERLTEST",undef);
my $rowcnt = 0;
#print 
while ( my ( $TABLE_CAT, $TABLE_SCHEM, $TABLE_NAME, $KEY_SEQ, $PK_NAME ) = $tabsth->fetchrow_array() ) {
  foreach ($TABLE_CAT, $TABLE_SCHEM, $TABLE_NAME, $KEY_SEQ, $PK_NAME) {
    $_ = "N/A" unless defined $_;
  }

  $rowcnt++;
  print "$TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$KEY_SEQ,$PK_NAME\n";
}
print "rowcnt: $rowcnt\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

__END__
