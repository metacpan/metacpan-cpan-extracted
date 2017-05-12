use strict;
use Test::More;
use Test::Deep;

sub n($) {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

BEGIN {
  if( eval{require Ima::DBI} ) {
    plan tests=>10;
#    plan 'no_plan';
  } else {
    plan skip_all => 'Ima::DBI not found';
  }
}

use Apache::DBI::Cache::ImaDBI;
use Apache::DBI::Cache use_bdb=>0, delimiter=>'^';
Apache::DBI::Cache::init;
my $stat=Apache::DBI::Cache::statistics;

BEGIN {
  package X;
  use base 'Apache::DBI::Cache::ImaDBI', 'Ima::DBI';
#  use base 'Ima::DBI';

  __PACKAGE__->set_db( Main=>'dbi:SQLite:dbname=x.sqlite' );
}

BEGIN {
  package Y;
  use base 'Apache::DBI::Cache::ImaDBI', 'Ima::DBI';
#  use base 'Ima::DBI';

  __PACKAGE__->set_db( Main=>'dbi:SQLite:dbname=x.sqlite' );
}

my $expected_stats=[0,0,0,0,0];
my $statkey='SQLite^dbname=x.sqlite^';

my $dbh1=X->db_Main;
$expected_stats->[0]++;		# new connection
$expected_stats->[2]++;		# usage count

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics0' );

can_ok( $dbh1, 'prepare' );
my $s1="$dbh1";
$s1=~s/^.+?=HASH//;
undef $dbh1;

my $dbh2=X->db_Main;
my $s2="$dbh2";
$s2=~s/^.+?=HASH//;
undef $dbh2;

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics1' );

Apache::DBI::Cache::request_cleanup;
$expected_stats->[1]++;		# free count

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics2' );

cmp_deeply( $s1, $s2,
	    n 'got the same handle' );


# here starts a new round. all handles have been freed.


$dbh1=Y->db_Main;
$expected_stats->[1]--;		# reuse connection
$expected_stats->[2]++;		# usage count

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics3' );

$s1="$dbh1";
$s1=~s/^.+?HASH//;
undef $dbh1;

cmp_deeply( $s1, $s2,
	    n 'got the same handle even for another class' );

$dbh2=X->db_Main;
$expected_stats->[0]++;		# new connection
$expected_stats->[2]++;		# usage count
$s2="$dbh2";
$s2=~s/^.+?HASH//;
undef $dbh2;

ok( $s1 ne $s2,
    n 'got a new handle while the first one is still used' );

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics4' );

Apache::DBI::Cache::request_cleanup;
$expected_stats->[1]++;		# free count
$expected_stats->[1]++;		# free count

cmp_deeply( $stat->{$statkey}, $expected_stats,
	    n 'statistics5' );

Apache::DBI::Cache::finish;

# Local Variables:
# mode: perl
# End:
