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

# LIVE test for karr k121 (U4): an index or a trigger of a partitioned table
# is carried down to every partition by the server. The partition has a copy
# of its own (an index related to the parent's by pg_inherits, a trigger with
# pg_trigger.tgparentid set), which belongs to the parent's and goes with it.
#
# WHAT IT ASSERTS: the diff writes the statement at the partitioned table
# alone, never one at a partition for a copy the server made; the statements
# run; the diff between the two databases is empty afterwards; and an index or
# a trigger a partition has of its own still shows up in the diff.
#
# WHY: before the fix the introspection read the copies as objects of the
# partition, and the diff wrote CREATE/DROP INDEX and CREATE/DROP TRIGGER at
# every partition too, which the server refuses.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t134a t134b );

sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub statements {
  my ($diff) = @_;
  return [ map { split /\n/, $_->as_sql } @{ $diff->operations } ];
}

sub start_over {
  my ($sql_a, $sql_b) = @_;
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
  }
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
}

my @base = (
  'CREATE TABLE public.p (id integer, v text) PARTITION BY RANGE (id)',
  'CREATE TABLE public.p1 PARTITION OF public.p FOR VALUES FROM (0) TO (100)',
  'CREATE FUNCTION public.f() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$',
);
my @with = (
  @base,
  'CREATE INDEX p_v_idx ON public.p (v)',
  'CREATE TRIGGER p_trg AFTER INSERT ON public.p FOR EACH ROW EXECUTE FUNCTION public.f()',
);

# The model: the copies are not there, the parent's are.
start_over([@with], []);
{
  my $model = catalog($dbh_a);
  is_deeply([ sort keys %{ $model->{indexes}{'public.p'} || {} } ], ['p_v_idx'],
    'the model has the index of the partitioned table');
  ok(!$model->{indexes}{'public.p1'} || !%{ $model->{indexes}{'public.p1'} },
    '... and none of the copy at the partition');
  is_deeply([ sort keys %{ $model->{triggers}{'public.p'} || {} } ], ['p_trg'],
    'the model has the trigger of the partitioned table');
  ok(!$model->{triggers}{'public.p1'} || !%{ $model->{triggers}{'public.p1'} },
    '... and none of the copy at the partition');
}

# (a) new at the parent
{
  start_over([@base], [@with]);
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  # karr k146: the index of a partitioned table is the one exception, it
  # gets an index at each partition and the attach (ON ONLY alone is invalid)
  my $sql = join "\n", grep { !/\A(?:CREATE INDEX \S+ ON public\.p1 |ALTER INDEX \S+ ATTACH PARTITION public\.p1_)/ }
    map { split /\n/, $_->as_sql } @{ $diff->operations };
  unlike($sql, qr/\bp1\b|public\.p1_/, "new at the parent: nothing but the index and its attach is written at the partition");
}
{
  start_over([@base], [@with]);
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  my @whole = map { $_->as_sql } @{ $diff->operations };
  is(scalar(@whole), 2, 'new at the parent: two operations');
  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @whole; $dbh_a->commit; 1 }, '... which run') or do { diag $@; $dbh_a->rollback };
  is_deeply(
    statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
    [], '... and the diff is empty afterwards');
}

# (b) gone from the parent
{
  start_over([@with], [@base]);
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  my @whole = map { $_->as_sql } @{ $diff->operations };
  is(scalar(@whole), 2, 'gone from the parent: two operations');
  unlike(join("\n", @whole), qr/p1/, '... none of them at the partition');
  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @whole; $dbh_a->commit; 1 }, '... which run') or do { diag $@; $dbh_a->rollback };
  is_deeply(
    statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
    [], '... and the diff is empty afterwards');
}

# (c) an index and a trigger of the partition's own are still diffed
{
  my @own = (
    @base,
    'CREATE INDEX p1_own_idx ON public.p1 (v)',
    'CREATE TRIGGER p1_own_trg AFTER INSERT ON public.p1 FOR EACH ROW EXECUTE FUNCTION public.f()',
  );
  start_over([@base], [@own]);
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  my $sql = join "\n", map { $_->as_sql } @{ $diff->operations };
  like($sql, qr/CREATE INDEX p1_own_idx ON public\.p1/, "a partition's own index is created");
  like($sql, qr/CREATE TRIGGER p1_own_trg/, "a partition's own trigger is created");
  ok(eval { $dbh_a->do($_->as_sql) for @{ $diff->operations }; 1 }, '... and they run') or diag $@;
  is_deeply(
    statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
    [], '... and the diff is empty afterwards');
}

done_testing;
