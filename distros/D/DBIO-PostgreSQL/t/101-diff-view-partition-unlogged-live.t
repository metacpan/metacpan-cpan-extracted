use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120 (4, 5, 6): the diff acts on what the model knows
# about a table -- which columns a view reads, what a partition or an
# inheriting table has from its parent, whether a table is unlogged.
#
# WHY it exists: t/101-diff-view-partition-unlogged.t pins the statements and
# the refusals, with models built by hand. Only a server says whether the
# model it hands out carries those facts, whether the statements are the ones
# it takes, and whether what they leave is what the target has. Until now the
# diff answered these cases with statements PostgreSQL refuses:
#
#   cannot alter type of a column used by a view or rule
#   cannot add column to a partition
#   public.p(integer) is not a function
#
# or with nothing (a table that is UNLOGGED in the target), or with an
# ordinary table where the target has one that inherits.
#
# The form of every case: database A is what there is, database B is what
# is wanted, and A is made into B with the diff between their catalogs. Two
# postconditions, the ones of core ADR 0060:
#
#  * where the diff is right, its statements run, and the diff between A and
#    B is empty afterwards;
#  * where it refuses, A reads afterwards as it did before.
#
# No class can declare a partition, an inheriting table or an unlogged one,
# so this is model against model throughout. Everything happens in two
# databases of this file's own (karr k81).

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t101a t101b );

# A model without what differs between any two databases.
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

# A is made into B with the diff between them. The statements are the ones
# given, they run, and nothing is left to do afterwards.
sub becomes {
  my ($label, $sql_a, $sql_b, $expect) = @_;
  start_over($sql_a, $sql_b);

  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  my $statements = eval { statements($diff) };
  ok($statements, "$label: the diff is built") or do { diag $@; return };
  is_deeply($statements, $expect, "$label: the statements") if $expect;

  # Run the statements whole: the lines above are split for comparing, and a
  # view's definition is several lines of one statement.
  my @whole = map { $_->as_sql } @{ $diff->operations };
  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @whole; $dbh_a->commit; 1 }, "$label: the statements run")
    or do { diag $@; diag join "\n", @whole; $dbh_a->rollback; return };

  is_deeply(
    statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
    [], "$label: afterwards the diff is empty");
}

# The diff between A and B is refused, and A is left as it was.
sub is_refused {
  my ($label, $sql_a, $sql_b, $expect) = @_;
  start_over($sql_a, $sql_b);
  my $before = catalog($dbh_a);
  throws_ok {
    DBIO::PostgreSQL::Diff->new(source => $before, target => catalog($dbh_b))->operations
  } $expect, "$label is refused";
  my $error = $@;
  is_deeply(catalog($dbh_a), $before, "$label: nothing has changed");
  return $error;
}

# What a table's columns are, as the two databases are compared by hand.
sub columns_of {
  my ($dbh, $table) = @_;
  return $dbh->selectall_arrayref(q{
    SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull::int,
           pg_catalog.pg_get_expr(d.adbin, d.adrelid), a.attidentity::text
    FROM pg_catalog.pg_attribute a
    LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE a.attrelid = ?::pg_catalog.regclass AND a.attnum > 0 AND NOT a.attisdropped
    ORDER BY a.attname}, undef, $table);
}
sub same_columns_ok {
  my ($label, @tables) = @_;
  is_deeply(columns_of($dbh_a, $_), columns_of($dbh_b, $_), "$label: $_ has the columns of the target")
    for @tables;
}

# ---------------------------------------------------------------------------
# 4. A column a view reads
# ---------------------------------------------------------------------------
{
  my @base = (
    'CREATE TABLE public.t (id integer, a integer, c text, d integer)',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE d > 0',
    'CREATE VIEW public.v_on_v AS SELECT a FROM public.v_a',
    'CREATE VIEW public.v_row AS SELECT t FROM public.t',
  );

  start_over(\@base, []);
  my $tables = catalog($dbh_a)->{tables};
  is_deeply($tables->{'public.v_a'}{depends_on_columns}, { 'public.t' => [qw( a d id )] },
    'the model has the columns a view reads, those of its WHERE among them');
  is_deeply($tables->{'public.v_on_v'}{depends_on_columns}, { 'public.v_a' => ['a'] },
    '... also where it reads a view');
  is_deeply([ @{ $tables->{'public.v_row'} }{qw( depends_on depends_on_columns )} ], [ ['public.t'], {} ],
    '... and none for a view that reads the whole row, which stands on the table all the same');

  # Views the target has are dropped and created again around the change
  # (karr k120, decision 2026-10-12): the server takes DROP, ALTER, CREATE in
  # one transaction, and the diff after it is empty (t/127 does the same
  # through Deploy, with the transaction proven).
  becomes('the type of a column a view reads',
    \@base, [ 'CREATE TABLE public.t (id integer, a bigint, c text, d integer)', @base[1 .. 3] ],
    [
      'DROP VIEW public.v_on_v;',
      'DROP VIEW public.v_a;',
      'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
      'CREATE VIEW public.v_a AS SELECT id,',
      '    a',
      '   FROM public.t',
      '  WHERE (d > 0);',
      'CREATE VIEW public.v_on_v AS SELECT a',
      '   FROM public.v_a;',
    ]);

  # A materialized view is not built anew for it (decision 2026-10-16):
  # refused, naming it, the database left as it was -- its rows and its index
  # with it. Directly, and through a view the diff would rebuild.
  my @mv = (
    'CREATE TABLE public.t (id integer, a integer)',
    'INSERT INTO public.t VALUES (1, 10), (2, 20)',
    'CREATE MATERIALIZED VIEW public.mv_a AS SELECT id, a FROM public.t',
    'CREATE INDEX mv_a_idx ON public.mv_a (id)',
  );
  my $mv_error = is_refused('the type of a column a materialized view reads',
    \@mv, [ 'CREATE TABLE public.t (id integer, a bigint)', 'INSERT INTO public.t VALUES (1, 10), (2, 20)', @mv[2 .. 3] ],
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint and is read by materialized view public\.mv_a$/m);
  is_deeply($dbh_a->selectall_arrayref('SELECT id, a FROM public.mv_a ORDER BY id'), [ [1, 10], [2, 20] ],
    '... and the materialized view keeps its rows');
  is_deeply($dbh_a->selectcol_arrayref(q{SELECT indexname FROM pg_indexes WHERE tablename = 'mv_a'}), ['mv_a_idx'],
    '... and its index');

  # The way out the refusal names: its DROP, and the diff again, which then
  # alters the column and creates the materialized view with its index.
  my @mv_drops = $mv_error =~ /^  (DROP [^\n]*);$/mg;
  is_deeply(\@mv_drops, [ 'DROP MATERIALIZED VIEW public.mv_a' ], 'the refusal names the materialized view to drop');
  ok(eval { $dbh_a->do($_) for @mv_drops; 1 }, 'the server takes that statement') or diag $@;
  {
    my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
    my @whole = eval { map { $_->as_sql } @{ $diff->operations } };
    ok(eval { $dbh_a->do($_) for @whole; 1 }, '... the diff after it runs') or diag $@;
    is_deeply(statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
      [], '... and leaves nothing to do');
  }

  my @mv_on_view = (
    'CREATE TABLE public.t (id integer, a integer)',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t',
    'CREATE MATERIALIZED VIEW public.mv_b AS SELECT a FROM public.v_a',
  );
  is_refused('the type of a column a view reads that a materialized view stands on',
    \@mv_on_view, [ 'CREATE TABLE public.t (id integer, a bigint)', @mv_on_view[1 .. 2] ],
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint and is read by materialized view public\.mv_b \(through view public\.v_a\)$/m);

  # A view only the database has is not the declaration's to create again.
  my $error = is_refused('the type of a column a view reads that the target does not have',
    \@base, [ 'CREATE TABLE public.t (id integer, a bigint, c text, d integer)', $base[3] ],
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint while view public\.v_a, view public\.v_on_v, which only the database has, depends on it$/m);

  # The way out the refusal names: its DROPs, and the diff again.
  my @drops = $error =~ /^  (DROP [^\n]*);$/mg;
  is_deeply(\@drops, [ 'DROP VIEW public.v_on_v', 'DROP VIEW public.v_a' ], 'the refusal names the views to drop, in order');
  ok(eval { $dbh_a->do($_) for @drops; 1 }, 'the server takes those statements') or diag $@;
  {
    my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
    is_deeply(statements($diff), [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
      'with the views dropped, the diff alters the column');
    ok(eval { $dbh_a->do($_) for map { $_->as_sql } @{ $diff->operations }; 1 }, '... which runs') or diag $@;
    is_deeply(statements(DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b))),
      [], '... and leaves nothing to do');
  }

  # Only the column that is read.
  becomes('the type of a column no view reads, on a table views read',
    \@base, [ @base, 'ALTER TABLE public.t ALTER COLUMN c TYPE character varying(10)' ],
    [ 'ALTER TABLE public.t ALTER COLUMN c TYPE character varying(10);' ]);
  becomes('NOT NULL and the default of a column a view reads',
    \@base, [ @base, 'ALTER TABLE public.t ALTER COLUMN a SET NOT NULL', 'ALTER TABLE public.t ALTER COLUMN a SET DEFAULT 1' ],
    [ 'ALTER TABLE public.t ALTER COLUMN a SET NOT NULL;', 'ALTER TABLE public.t ALTER COLUMN a SET DEFAULT 1;' ]);

  # A column that goes while a view reads the whole row: the view's text
  # stays, the column is dropped, and the server takes it.
  becomes('a column dropped under a view that reads the whole row',
    [ $base[0], $base[3] ], [ 'CREATE TABLE public.t (id integer, a integer, d integer)', $base[3] ],
    [ 'ALTER TABLE public.t DROP COLUMN c;' ]);
}

# ---------------------------------------------------------------------------
# 5. Partitions
# ---------------------------------------------------------------------------
{
  my @m = (
    'CREATE TABLE public.m (id bigint NOT NULL, d date NOT NULL, v text) PARTITION BY RANGE (d)',
    q{CREATE TABLE public.m_2026 PARTITION OF public.m FOR VALUES FROM ('2026-01-01') TO ('2027-01-01')},
    # one whose name sorts ahead of the table it belongs to
    q{CREATE TABLE public.a_part PARTITION OF public.m FOR VALUES FROM ('2025-01-01') TO ('2026-01-01')},
    # and one that is partitioned itself
    q{CREATE TABLE public.m_2027 PARTITION OF public.m FOR VALUES FROM ('2027-01-01') TO ('2028-01-01') PARTITION BY LIST (id)},
    'CREATE TABLE public.m_2027_1 PARTITION OF public.m_2027 FOR VALUES IN (1)',
  );
  my @all = qw( public.m public.a_part public.m_2026 public.m_2027 public.m_2027_1 );
  my @x   = (@m, 'ALTER TABLE public.m ADD COLUMN x integer');

  start_over(\@m, []);
  is_deeply([ map { $_->{partition_of} } @{ catalog($dbh_a)->{tables} }{@all} ],
    [ undef, 'public.m', 'public.m', 'public.m', 'public.m_2027' ],
    'the model has the table each partition belongs to');

  becomes('a column added to a partitioned table',
    \@m, [ @m, 'ALTER TABLE public.m ADD COLUMN x integer NOT NULL DEFAULT 5' ],
    [ 'ALTER TABLE public.m ADD COLUMN x integer NOT NULL DEFAULT 5;' ]);
  same_columns_ok('a column added', @all);

  becomes('a column added to a partitioned table as an identity',
    \@m, [ @m, 'ALTER TABLE public.m ADD COLUMN seq bigint GENERATED BY DEFAULT AS IDENTITY' ],
    [ 'ALTER TABLE public.m ADD COLUMN seq bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY;' ]);

  becomes('a column dropped from a partitioned table',
    \@x, \@m, [ 'ALTER TABLE public.m DROP COLUMN x;' ]);

  becomes('the type of a column of a partitioned table',
    \@x, [ @x, 'ALTER TABLE public.m ALTER COLUMN x TYPE bigint' ],
    [ 'ALTER TABLE public.m ALTER COLUMN x TYPE bigint;' ]);
  same_columns_ok('a type altered', @all);

  becomes('an identity added to a column of a partitioned table',
    \@m, [ @m, 'ALTER TABLE public.m ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY' ],
    [ 'ALTER TABLE public.m ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY;' ]);

  becomes('NOT NULL and a default set on a partitioned table',
    \@x, [ @x, 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9', 'ALTER TABLE public.m ALTER COLUMN v SET NOT NULL' ],
    [ 'ALTER TABLE public.m ALTER COLUMN v SET NOT NULL;', 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9;' ]);

  # What is a partition's own.
  my @own = (@x, 'ALTER TABLE public.m_2026 ALTER COLUMN x SET DEFAULT 7');
  becomes('a default of a partition alone',
    \@x, \@own, [ 'ALTER TABLE public.m_2026 ALTER COLUMN x SET DEFAULT 7;' ]);
  becomes('a new column with a default of a partition alone',
    \@m, \@own,
    [ 'ALTER TABLE public.m ADD COLUMN x integer;', 'ALTER TABLE public.m_2026 ALTER COLUMN x SET DEFAULT 7;' ]);
  becomes('a default changed on the partitioned table, with a partition that keeps its own',
    \@own, [ @x, 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9', 'ALTER TABLE public.m_2026 ALTER COLUMN x SET DEFAULT 7' ],
    [ 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9;', 'ALTER TABLE public.m_2026 ALTER COLUMN x SET DEFAULT 7;' ]);
  same_columns_ok('a default kept', @all);
  becomes('NOT NULL of a partition alone',
    \@m, [ @m, 'ALTER TABLE public.m_2026 ALTER COLUMN v SET NOT NULL' ],
    [ 'ALTER TABLE public.m_2026 ALTER COLUMN v SET NOT NULL;' ]);

  # DROP NOT NULL above leaves a NOT NULL a partition has of its own. The
  # model does not say whose a NOT NULL is, so each partition is asked too.
  becomes('NOT NULL dropped from a partitioned table, one partition having had its own',
    [ @m, 'ALTER TABLE public.m_2026 ALTER COLUMN v SET NOT NULL', 'ALTER TABLE public.m ALTER COLUMN v SET NOT NULL' ], \@m,
    [ map { "ALTER TABLE public.$_ ALTER COLUMN v DROP NOT NULL;" } qw( m a_part m_2026 m_2027 m_2027_1 ) ]);
  same_columns_ok('NOT NULL dropped', @all);

  is_refused('a partition that is none in the target',
    \@m, [ @m, 'ALTER TABLE public.m DETACH PARTITION public.m_2026' ],
    qr/\Arefusing to diff: table public\.m_2026 is a partition of public\.m in the database and a table of its own in the target$/m);

  # A view on a partition holds the column of the partitioned table too, and
  # is rebuilt around the change when the target has it.
  becomes('the type of a column of a partitioned table that a view reads in a partition',
    [ @x, 'CREATE VIEW public.v_part AS SELECT x FROM public.m_2026' ],
    [ @x, 'ALTER TABLE public.m ALTER COLUMN x TYPE bigint', 'CREATE VIEW public.v_part AS SELECT x FROM public.m_2026' ]);
}

# ---------------------------------------------------------------------------
# 5. Inheritance
# ---------------------------------------------------------------------------
{
  my @inh = (
    'CREATE TABLE public.p_inh (a integer, b text)',
    'CREATE TABLE public.c_inh (c integer) INHERITS (public.p_inh)',
    # b is the child's own definition as well
    'CREATE TABLE public.c_merged (b text, c integer) INHERITS (public.p_inh)',
  );
  my @children = qw( public.c_inh public.c_merged );

  start_over(\@inh, []);
  my $model = catalog($dbh_a);
  is_deeply([ map { $_->{inherits} } @{ $model->{tables} }{ 'public.p_inh', @children } ],
    [ [], ['public.p_inh'], ['public.p_inh'] ], 'the model has the tables a table inherits from');
  is_deeply({ map { $_->{column_name} => $_->{is_local} } @{ $model->{columns}{'public.c_merged'} } },
    { a => 0, b => 1, c => 1 }, '... and which columns a table defines itself');

  becomes('a column added to a table others inherit from, and one of a child alone',
    \@inh, [ @inh, 'ALTER TABLE public.p_inh ADD COLUMN n1 integer NOT NULL DEFAULT 5', 'ALTER TABLE public.c_inh ADD COLUMN own1 integer' ],
    [ 'ALTER TABLE public.p_inh ADD COLUMN n1 integer NOT NULL DEFAULT 5;', 'ALTER TABLE public.c_inh ADD COLUMN own1 integer;' ]);
  same_columns_ok('a column added', 'public.p_inh', @children);

  becomes('the type of an inherited column, and a default of a child alone',
    \@inh, [ @inh, 'ALTER TABLE public.p_inh ALTER COLUMN a TYPE bigint', 'ALTER TABLE public.c_inh ALTER COLUMN a SET DEFAULT 7' ],
    [ 'ALTER TABLE public.p_inh ALTER COLUMN a TYPE bigint;', 'ALTER TABLE public.c_inh ALTER COLUMN a SET DEFAULT 7;' ]);
  same_columns_ok('a type altered', 'public.p_inh', @children);

  # An identity is not inherited.
  becomes('an identity added to a column others inherit',
    \@inh, [ @inh, 'ALTER TABLE public.p_inh ALTER COLUMN a SET NOT NULL', 'ALTER TABLE public.p_inh ALTER COLUMN a ADD GENERATED ALWAYS AS IDENTITY' ],
    [ 'ALTER TABLE public.p_inh ALTER COLUMN a SET NOT NULL;', 'ALTER TABLE public.p_inh ALTER COLUMN a ADD GENERATED ALWAYS AS IDENTITY;' ]);

  # DROP COLUMN goes down to c_inh, whose b is inherited and no more. In
  # c_merged it stays, as the child's own.
  becomes('a column dropped from a table, kept by the child that defines it itself',
    \@inh, [ @inh, 'ALTER TABLE public.p_inh DROP COLUMN b' ],
    [ 'ALTER TABLE public.p_inh DROP COLUMN b;' ]);
  same_columns_ok('a column dropped above', @children);
  becomes('a column dropped from a table and from the child that defines it itself',
    \@inh, [ @inh, 'ALTER TABLE public.p_inh DROP COLUMN b', 'ALTER TABLE public.c_merged DROP COLUMN b' ],
    [ 'ALTER TABLE public.p_inh DROP COLUMN b;', 'ALTER TABLE public.c_merged DROP COLUMN b;' ]);

  my $error = is_refused('a table to create that inherits',
    [ $inh[0] ], [ @inh[0, 1] ],
    qr/\Arefusing to diff: table public\.c_inh inherits from public\.p_inh in the target and is not in the database, and the diff cannot create it$/m);
  like($error, qr/CREATE TABLE public\.c_inh \(a integer, b text, c integer\)/,
    '... naming the ordinary table that would have come of it');

  is_refused('a table that no longer inherits',
    \@inh, [ @inh, 'ALTER TABLE public.c_inh NO INHERIT public.p_inh' ],
    qr/\Arefusing to diff: table public\.c_inh is a table that inherits from public\.p_inh in the database and a table of its own in the target$/m);
}

# ---------------------------------------------------------------------------
# 6. UNLOGGED
# ---------------------------------------------------------------------------
{
  my $persistence = sub {
    my ($table) = @_;
    return scalar $dbh_a->selectrow_array(
      'SELECT relpersistence FROM pg_catalog.pg_class WHERE oid = ?::pg_catalog.regclass', undef, $table);
  };

  becomes('an unlogged table to create',
    [], [ 'CREATE UNLOGGED TABLE public.u (id integer)' ],
    [ 'CREATE UNLOGGED TABLE public.u (id integer);' ]);
  is($persistence->('public.u'), 'u', '... is unlogged in the catalog');

  becomes('a table that is unlogged in the target',
    [ 'CREATE TABLE public.u (id integer PRIMARY KEY)' ], [ 'CREATE UNLOGGED TABLE public.u (id integer PRIMARY KEY)' ],
    [ 'ALTER TABLE public.u SET UNLOGGED;' ]);
  is($persistence->('public.u'), 'u', '... is unlogged in the catalog');

  becomes('a table that is logged in the target',
    [ 'CREATE UNLOGGED TABLE public.u (id integer PRIMARY KEY)' ], [ 'CREATE TABLE public.u (id integer PRIMARY KEY)' ],
    [ 'ALTER TABLE public.u SET LOGGED;' ]);
  is($persistence->('public.u'), 'p', '... is permanent in the catalog');

  my @m = (
    'CREATE TABLE public.m (id bigint NOT NULL, d date NOT NULL) PARTITION BY RANGE (d)',
    q{CREATE TABLE public.m_2026 PARTITION OF public.m FOR VALUES FROM ('2026-01-01') TO ('2027-01-01')},
  );
  becomes('a partition that is unlogged in the target',
    \@m, [ @m, 'ALTER TABLE public.m_2026 SET UNLOGGED' ], [ 'ALTER TABLE public.m_2026 SET UNLOGGED;' ]);

  # A temporary table is in a schema of the session, which no model reads.
  start_over([ 'CREATE TEMPORARY TABLE tmp_t101 (id integer)' ], []);
  is_deeply([ grep { /tmp_t101/ } keys %{ catalog($dbh_a)->{tables} } ], [],
    'a temporary table is not in the model');
  $dbh_a->do('DROP TABLE tmp_t101');
}

# ---------------------------------------------------------------------------
# A procedure
# ---------------------------------------------------------------------------
{
  my @routines = (
    q{CREATE PROCEDURE public.p_proc(n integer) LANGUAGE sql AS 'SELECT 1'},
    q{CREATE FUNCTION public.f_fn(n integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
  );
  start_over(\@routines, []);
  is_deeply({ map { $_->{function_name} => $_->{kind} } values %{ catalog($dbh_a)->{functions} } },
    { p_proc => 'p', f_fn => 'f' }, 'the model has which routine is a procedure');

  becomes('a procedure and a function that go',
    \@routines, [],
    [ 'DROP FUNCTION public.f_fn(n integer);', 'DROP PROCEDURE public.p_proc(IN n integer);' ]);
}

$_->disconnect for $dbh_a, $dbh_b;

done_testing;
