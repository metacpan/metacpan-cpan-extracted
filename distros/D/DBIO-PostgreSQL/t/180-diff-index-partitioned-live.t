use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

LiveServer->require_server;

# LIVE test for karr k146: an index on a partitioned table.
#
# WHAT IT ASSERTS: the diff creates the index of a partitioned table so that it
# is valid -- at the table and at every partition, a partition that is
# partitioned itself included -- and a second diff is empty.
#
# WHY: pg_get_indexdef writes such an index ON ONLY, and an index made from
# that text is invalid until the partitions have indexes attached.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t180a t180b );

sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub diff_of { DBIO::PostgreSQL::Diff->new(source => catalog($_[0]), target => catalog($_[1])) }
sub sql_of  { [ map { split /\n/, $_->as_sql } @{ $_[0]->operations } ] }

sub start_over {
  my ($sql_a, $sql_b) = @_;
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
  }
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
}

# every index of the tree below public.pt: name => validity, copies included
sub validity {
  my ($dbh) = @_;
  return $dbh->selectall_hashref(q{
    SELECT c.relname AS name, i.indisvalid AS valid, i.indrelid::regclass::text AS tab
    FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND i.indrelid::regclass::text LIKE 'pt%'
  }, 'name');
}

sub runs_and_settles {
  my ($label, $diff, $count) = @_;
  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @{ sql_of($diff) }; $dbh_a->commit; 1 }, "$label: the statements run")
    or do { diag $@; $dbh_a->rollback };
  my $valid = validity($dbh_a);
  is(scalar(keys %$valid), $count, "$label: $count indexes in the tree") or diag join ' ', sort keys %$valid;
  is_deeply([ grep { !$valid->{$_}{valid} } sort keys %$valid ], [], "$label: every index of the tree is valid");
  is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], "$label: the second diff is empty");
}

my @tables = (
  'CREATE TABLE public.pt (id integer NOT NULL, tag text, grp integer NOT NULL) PARTITION BY RANGE (id)',
  'CREATE TABLE public.pt1 PARTITION OF public.pt FOR VALUES FROM (0) TO (100)',
  'CREATE TABLE public.pt2 PARTITION OF public.pt FOR VALUES FROM (100) TO (200) PARTITION BY LIST (grp)',
  'CREATE TABLE public.pt2a PARTITION OF public.pt2 FOR VALUES IN (1)',
  'CREATE TABLE public.pt2b PARTITION OF public.pt2 FOR VALUES IN (2)',
);

# The text alone is invalid: the claim the fix stands on.
start_over([@tables, 'CREATE INDEX pt_tag ON pt (tag)'], []);
like(catalog($dbh_a)->{indexes}{'public.pt'}{pt_tag}{definition}, qr/ON ONLY public\.pt /,
  'the catalog writes the index of a partitioned table ON ONLY');

# A plain index, two levels of partitions.
start_over([@tables], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ]);
{
  my $diff = diff_of($dbh_a, $dbh_b);
  like(join("\n", @{ sql_of($diff) }), qr/ATTACH PARTITION/, 'create: the partitions are attached');
  runs_and_settles("create", $diff, 5);
}

# Unique (the key of the partitions included), partial, expression.
start_over([@tables], [ @tables,
  'CREATE UNIQUE INDEX pt_u ON public.pt (id, grp, tag)',
  'CREATE INDEX pt_part ON public.pt (grp) WHERE grp > 0',
  'CREATE INDEX pt_expr ON public.pt (lower(tag))',
  'CREATE INDEX pt_tag ON public.pt (tag)',
]);
runs_and_settles('unique, partial, expression, same columns twice', diff_of($dbh_a, $dbh_b), 20);

# A changed index: dropped, created again, valid.
start_over([ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag, grp)' ]);
runs_and_settles('changed', diff_of($dbh_a, $dbh_b), 5);

# Equal databases: nothing.
start_over([ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ]);
is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], 'the same index on both sides: no operation');

done_testing;
