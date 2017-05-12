#!perl -w -I./t
#/*!
#  @file           054fetch.t
#  @author         ThomasS
#  @ingroup        dbd::MaxDB
#  @brief          tests fetch command
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
use DBI qw( neat_list );
use MaxDBTest;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 4;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::Test(1);

print " Test 2: set LongReadLen option\n";
$dbh->{LongReadLen} = 1000;
MaxDBTest::Test(1);

print " Test 3: set ChopBlanks option\n";
$dbh->{ChopBlanks} = 1;
MaxDBTest::Test(1);

print " Test 4: test fetch command\n";
my $sth = $dbh->prepare ("SELECT * FROM TABLES WHERE TYPE = ?");
if ($sth) {
  my ($rc, @row, $typename, $rowcnt);
  $typename = "SYSTEM";
  $rc = 0;
  $rc = $sth->bind_param (1, $typename);
  $rc |= $sth->execute();
  $rowcnt = 0;
  while (@row = $sth->fetchrow()) {
    $rowcnt++;
    print neat_list ( \@row, 40, " | "), "\n";
  }
  $rc |= $sth->finish ();
  print "\nNr. of rows selected: $rowcnt\n";
  MaxDBTest::Test($rc);
} else {
  MaxDBTest::Test(0);
}

__END__

