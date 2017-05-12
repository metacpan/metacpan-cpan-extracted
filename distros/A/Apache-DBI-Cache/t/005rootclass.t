use strict;
use Test::More tests => 9;
#use Test::More 'no_plan';
use Test::Deep;

sub n($) {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

BEGIN {
  package X;
  use base 'DBI';
  $INC{'X.pm'}=1;

  package X::db;
  use base 'DBI::db';

  package X::st;
  use base 'DBI::st';
}

BEGIN {
  package Y;
  use base 'DBI';
  $INC{'Y.pm'}=1;

  package Y::db;
  use base 'DBI::db';

  package Y::st;
  use base 'DBI::st';
}

use Apache::DBI::Cache use_bdb=>0, delimiter=>'^';
Apache::DBI::Cache::init;

my $stat=Apache::DBI::Cache::statistics;

my ($dsn, $statkey);
if( eval {require DBD::SQLite;} ) {
  print "# using DBD::SQLite\n";
  $dsn='dbi:SQLite:dbname=x.sqlite';
  $statkey='SQLite^dbname=x.sqlite^';
} else {
  print "# using DBD::DBM\n";
  $dsn='dbi:DBM:f_dir=tmp1';
  $statkey='DBM^f_dir=tmp1^';
}

my $expected_stats=[0,0,0,0,0];

my ($dbh1, $dbh2);
$dbh1=X->connect($dsn);
$expected_stats->[0]++;		# new connection
$expected_stats->[2]++;		# usage count

cmp_deeply ref $dbh1, 'X::db', n 'ref $dbh is X::db';

$dbh1="$dbh1";
$expected_stats->[1]++;		# free count

$dbh2=X->connect($dsn);
$expected_stats->[1]--;		# free count
$expected_stats->[2]++;		# usage count

$dbh2="$dbh2";
$expected_stats->[1]++;		# free count

cmp_deeply $dbh1, $dbh2, n "got identical handles";

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics0' );

$dbh1=X->connect($dsn);
$expected_stats->[1]--;		# free count
$expected_stats->[2]++;		# usage count

$dbh2=X->connect($dsn);
$expected_stats->[0]++;		# new connection
$expected_stats->[2]++;		# usage count

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics1' );

$dbh1="$dbh1";
$expected_stats->[1]++;		# free count
$dbh2="$dbh2";
$expected_stats->[1]++;		# free count

ok $dbh1 ne $dbh2, n "got different handles";

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics2' );

$dbh1=Y->connect($dsn);
$expected_stats->[1]--;		# free count
$expected_stats->[2]++;		# usage count

cmp_deeply ref $dbh1, 'Y::db', n 'ref $dbh is Y::db';

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics3' );


# now $dbh1 is Y::db.
# this next first allocates the remaining free handle
# then frees $dbh1 remembering its memory address
# then reallocates it as X::db
# and compares the 2 addresses

$dbh2=X->connect($dsn);
$expected_stats->[0]++;		# new connection
$expected_stats->[2]++;		# usage count

my $s1="$dbh1";
undef $dbh1;
$expected_stats->[1]++;		# free count
$dbh1=X->connect($dsn);
$expected_stats->[1]--;		# free count
$expected_stats->[2]++;		# usage count

my $s2="$dbh1";

$s1=~s/^.+?=HASH//;
$s2=~s/^.+?=HASH//;

cmp_deeply $s1, $s2, n 'got really the same handle even for another root class';

Apache::DBI::Cache::finish;

# Local Variables:
# mode: perl
# End:
