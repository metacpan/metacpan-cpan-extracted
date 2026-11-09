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

# LIVE test for karr k140: a foreign key on (or onto) a partitioned table.
#
# The server copies a foreign key of a partitioned table down to every
# partition (pg_constraint.conparentid set), and a foreign key onto a
# partitioned table is made of one constraint per partition it points at.
# Those copies belong to the key that was declared and go with it.
#
# WHAT IT ASSERTS: the model holds the declared key only; the diff between two
# databases that hold the same keys is empty; a key created, dropped or changed
# is one statement at the declared table, never one at a partition or at a
# helper constraint of the server's, and the statements run.
#
# WHY: read as keys of their own, the copies made a create fail with "already
# exists", a drop with "does not exist", a changed action with "cannot drop
# inherited constraint", and a key onto a partitioned table asked for helper
# constraints (ref_plain_fk_1) to be made and dropped.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t161a t161b );

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

sub fk_names {
  my ($dbh, $table) = @_;
  my $model = catalog($dbh);
  return [ sort map { $_->{constraint_name} } @{ $model->{foreign_keys}{$table} || [] } ];
}

sub runs_and_settles {
  my ($label, $diff) = @_;
  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @{ sql_of($diff) }; $dbh_a->commit; 1 }, "$label: the statements run")
    or do { diag $@; $dbh_a->rollback };
  is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], "$label: the diff is empty afterwards");
}

my @tables = (
  'CREATE TABLE public.pt (id integer NOT NULL, PRIMARY KEY (id)) PARTITION BY RANGE (id)',
  'CREATE TABLE public.pt1 PARTITION OF public.pt FOR VALUES FROM (0) TO (100)',
  'CREATE TABLE public.pt2 PARTITION OF public.pt FOR VALUES FROM (100) TO (200)',
  'CREATE TABLE public.plain (id integer PRIMARY KEY)',
  'CREATE TABLE public.ref_part (id integer NOT NULL, pid integer NOT NULL, PRIMARY KEY (id, pid)) PARTITION BY RANGE (id)',
  'CREATE TABLE public.ref_part1 PARTITION OF public.ref_part FOR VALUES FROM (0) TO (100)',
  'CREATE TABLE public.ref_plain (id integer PRIMARY KEY, pid integer NOT NULL)',
);
# a partitioned table referencing / a partitioned table referenced
my $out_fk = 'ALTER TABLE public.ref_part ADD CONSTRAINT ref_part_fk FOREIGN KEY (pid) REFERENCES public.plain (id)';
my $in_fk  = 'ALTER TABLE public.ref_plain ADD CONSTRAINT ref_plain_fk FOREIGN KEY (pid) REFERENCES public.pt (id)';
my $helper = qr/ref_part1|ref_plain_fk_\d|\bpt1\b|\bpt2\b/;

# The model: the declared keys alone.
start_over([ @tables, $out_fk, $in_fk ], []);
is_deeply(fk_names($dbh_a, 'public.ref_part'), ['ref_part_fk'],
  'the model has the key of the partitioned table');
is_deeply(fk_names($dbh_a, 'public.ref_part1'), [], '... not its copy at the partition');
is_deeply(fk_names($dbh_a, 'public.ref_plain'), ['ref_plain_fk'],
  'a key onto a partitioned table: one key, not one per partition');

# Equal databases: nothing to do.
start_over([ @tables, $out_fk, $in_fk ], [ @tables, $out_fk, $in_fk ]);
is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], 'the same keys on both sides: no operation');

# Create: one statement each, at the declared table.
start_over([@tables], [ @tables, $out_fk, $in_fk ]);
{
  my $diff = diff_of($dbh_a, $dbh_b);
  my $sql = sql_of($diff);
  is(scalar(@$sql), 2, 'create: two statements');
  unlike(join("\n", @$sql), $helper, '... none at a partition or a helper');
  runs_and_settles('create', $diff);
}

# Drop.
start_over([ @tables, $out_fk, $in_fk ], [@tables]);
{
  my $diff = diff_of($dbh_a, $dbh_b);
  my $sql = sql_of($diff);
  is(scalar(@$sql), 2, 'drop: two statements');
  unlike(join("\n", @$sql), $helper, '... none at a partition or a helper');
  runs_and_settles('drop', $diff);
}

# Changed action.
my $out_cascade = "$out_fk ON DELETE CASCADE";
my $in_cascade  = "$in_fk ON DELETE CASCADE";
start_over([ @tables, $out_fk, $in_fk ], [ @tables, $out_cascade, $in_cascade ]);
{
  my $diff = diff_of($dbh_a, $dbh_b);
  my $sql = sql_of($diff);
  is(scalar(@$sql), 4, 'changed action: a drop and a create for each key');
  unlike(join("\n", @$sql), $helper, '... none at a partition or a helper');
  runs_and_settles('changed action', $diff);
}

done_testing;
