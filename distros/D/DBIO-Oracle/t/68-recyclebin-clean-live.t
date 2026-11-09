use strict;
use warnings;

use Test::More;
use DBI;

# LIVE (karr k43). A live test file that creates tables must not leave them
# in the Oracle recyclebin of the test user: DROP TABLE without PURGE (and
# without ALTER SESSION SET recyclebin = OFF) keeps the table, its indexes
# and constraints there, and a suite run piles up ~20 entries. The claim
# pinned here: running each of these files leaves user_recyclebin with as
# many entries as before. The files are run as child processes, so this one
# adds their runtime to the suite.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test.'
  unless ($dsn && $user && $pass);

my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });

sub bin_count {
  return ($dbh->selectrow_array('SELECT COUNT(*) FROM user_recyclebin'))[0];
}

for my $file (qw(t/12-oracle-hq.t t/22-oracle-hq-core.t t/40-datetime-oracle.t)) {
  my $before = bin_count();
  my $out = `"$^X" -Ilib "$file" 2>&1`;
  my $status = $?;
  is $status, 0, "$file passes" or diag $out;
  is bin_count(), $before, "$file leaves no recyclebin entries";
}

done_testing;
