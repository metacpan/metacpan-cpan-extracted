use strict;
use warnings;
use Test::More;

# LIVE test for the MySQL '?' placeholder contract (karr #19 WP1/WP2). MySQL/DBD
# speaks '?' natively, so DBIO::MySQL::EV::Storage::_transform_sql is IDENTITY:
# the sql_maker '?' output must reach EV::MariaDB unchanged and bind correctly
# through prepare + execute. This is the exact opposite of the PostgreSQL twin
# (which rewrites '?' -> '$N'); a dialect rewrite creeping into the MySQL
# transport would make these bound queries fail or misbind.
#
# WHY live: proving '?' binds correctly end-to-end requires a real server
# evaluating the prepared statement with real parameters over EV::MariaDB.
#
# Dogfoods DBIO::MySQL::EV::TestHarness.

use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

my $h = DBIO::MySQL::EV::TestHarness->new;

# A pooled connection is enough: run a bound expression whose result proves the
# '?' placeholders were bound server-side (arithmetic + a string bind).
my @per_conn = $h->run_on_each_pooled_connection(2, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn,
    q{SELECT ? + ? AS total, ? AS label}, [ 20, 22, 'native-q' ]);
});

is scalar(@per_conn), 2, 'bound query ran on 2 distinct pooled connections';

for my $i (0 .. $#per_conn) {
  my $row = $per_conn[$i][0];
  is $row->[0], 42,
    "connection $i: '? + ?' bound and computed server-side (20 + 22 = 42)";
  is $row->[1], 'native-q',
    "connection $i: string '?' bind returned verbatim (no ?->\$N rewrite)";
}

# Also drive a bindless query on the same seam to prove the query() (non-prepare)
# path is unaffected -- both branches of the executor keep '?' semantics native.
my @bindless = $h->run_on_each_pooled_connection(1, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, q{SELECT 42 AS answer});
});
is $bindless[0][0][0], 42, 'bindless query on the pooled connection resolves';

$h->disconnect;

done_testing;
