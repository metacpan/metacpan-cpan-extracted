#!perl -w -I./t
#/*!
#  @file           059tableinfo.t
#  @author         ThomasS
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
   $tests = 5;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

my $rc;

print "1..$tests\n";
MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
$dbh->{ChopBlanks} = 1;
MaxDBTest::endTest();

MaxDBTest::beginTest("table info");
my $tabsth = $dbh->table_info();

print "Qualifier      Owner       Tablename      Type  Remarks\n";
print "=============  ==========  =============  ====  ===========\n\n";

my $rowcnt = 0;
while ( my ( $qual, $owner, $name, $type, $remarks ) = $tabsth->fetchrow_array() ) {
  foreach ($qual, $owner, $name, $type, $remarks) {
    $_ = "N/A" unless defined $_;
  }

  $rowcnt++;
  printf "%-13s %-10s %-15s %-7s %s\n", $qual, $owner, $name, $type, $remarks;
}
print "rowcnt: $rowcnt\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("tables");
my @tables = $dbh->tables();

print "Table\n";
print "=====\n\n";
foreach my $table ( @tables ) {
  print "$table\n";
}
MaxDBTest::endTest();

MaxDBTest::beginTest("type info all");
my $dbtypes = $dbh->type_info_all();
my $assocref = @$dbtypes[0];

print "\n\n";
print "Type info fields\n";
print "================\n\n";
while ( ($key, $value) = each(%$assocref)) {
  printf "%-20s %d\n", $key, $value;
}

my $dbarray;
my %assoc = %$assocref;

print "\n\n";
print "TYPE_NAME         COLUMN_SIZE\n";
print "================= ===========\n\n";
splice (@$dbtypes, 0, 1);
foreach $dbarray ( @$dbtypes ) {
  printf "%-17s %-10s\n", @$dbarray[$assoc{"TYPE_NAME"}], @$dbarray[$assoc{"COLUMN_SIZE"}];
}
print "\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

__END__
