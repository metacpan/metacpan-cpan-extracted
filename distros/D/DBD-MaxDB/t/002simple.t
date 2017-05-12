#!/usr/bin/perl -I./t
$| = 1;

use DBI qw(:sql_types);
use MaxDBTest;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 2;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";

MaxDBTest::Test(1);

print " Test 2: connecting to the database\n";
#DBI->trace(2);
my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
$dbh->{AutoCommit} = 1;

MaxDBTest::Test(1);


__END__




