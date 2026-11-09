use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k106, k107, k108, k109: a diff that drops things can be
# applied.
#
# WHY it exists: t/92 pins the order of the operations; only a server says
# whether that order is one it accepts. Each case here is a database that
# holds something the schema does not declare -- in the combinations where
# one of those things hangs on another -- and the claim is always the same
# three: the diff applies, what the schema declares is still there, and a
# second diff finds nothing left to do. Before the diff ordered its drops,
# every one of these died in apply on a statement naming an object the
# statement before it had just removed, or one that something still used.
#
# Every database here is private (karr k81): extensions are installed and
# dropped, and the deploys are unrestricted.

my %available;
{
  my $h = LiveServer->control_dbh;
  %available = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions}
  ) };
  note 'server ' . $h->selectrow_array('SHOW server_version');
  $h->disconnect;
}

{
  package T93::Bare;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# One table with a secondary index: what stays in every case below.
{
  package T93::Keep::Result::Keep;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('keep');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0 },
    a  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index(keep_a_idx => { columns => ['a'] });
}
for my $class (qw( T93::Keep T93::KeepVector )) {
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class(Keep => 'T93::Keep::Result::Keep');
}
T93::KeepVector->pg_extensions('vector');

{
  package T93::Postgis;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  # in the driver's table of the family (ADR 0066), whose distribution is no
  # dependency of this one: the plain class stands in.
  __PACKAGE__->pg_extensions(
    postgis          => { class => 'DBIO::PostgreSQL::Extension' },
    postgis_topology => { class => 'DBIO::PostgreSQL::Extension' },
  );
}

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

# A private database with $class installed and @sql run on top of it.
sub database_with {
  my ($tag, $class, @sql) = @_;
  my $schema = $class->connect(PrivatePgDatabase->create($tag), @CONNECT);
  $schema->pg_deploy->install;
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @sql;
  return ($schema, $dbh);
}

# The three claims. Returns the statements of the first diff.
sub applies_and_settles {
  my ($label, $schema) = @_;
  my $deploy = $schema->pg_deploy;

  my $diff = eval { $deploy->diff };
  ok($diff, "$label: the diff is built") or do { diag $@; return [] };
  note $diff->as_sql;
  ok($diff->has_changes, "$label: there is something to do");

  my $risky = () = $diff->destructive_operations;   # the cases drop or narrow: released where the diff says so
  ok(eval { $deploy->apply($diff, allow_destructive => $risky ? 1 : 0); 1 }, "$label: apply runs through")
    or diag "$@\n" . $diff->as_sql;

  my $again = $deploy->diff;
  ok(!$again->has_changes, "$label: a second diff finds nothing left to do")
    or diag $again->as_sql;

  return [ grep { /\S/ } split /\n/, $diff->as_sql ];
}

sub position {
  my ($statements, $re) = @_;
  my @at = grep { $statements->[$_] =~ $re } 0 .. $#$statements;
  return @at == 1 ? $at[0] : undef;
}

sub comes_before {
  my ($statements, $first, $then, $why) = @_;
  my ($a, $b) = map { position($statements, $_) } $first, $then;
  ok(defined $a && defined $b && $a < $b, $why)
    or diag "wanted $first before $then in:\n" . join("\n", @$statements);
}

sub keep_is_intact {
  my ($label, $dbh) = @_;
  is_deeply(
    $dbh->selectcol_arrayref(q{
      SELECT a.attname FROM pg_catalog.pg_attribute a
      WHERE a.attrelid = 'public.keep'::pg_catalog.regclass
        AND a.attnum > 0 AND NOT a.attisdropped
      ORDER BY a.attnum}),
    [qw( id a )], "$label: the declared table has its declared columns");
  is_deeply(
    $dbh->selectcol_arrayref(q{
      SELECT indexname FROM pg_catalog.pg_indexes
      WHERE schemaname = 'public' AND tablename = 'keep' ORDER BY 1}),
    [qw( keep_a_idx keep_pkey )], "$label: and its declared indexes");
}

# ---------------------------------------------------------------------------
# k109: a schema the target does not have, with everything in it
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = database_with(t93ns => 'T93::Keep');
  ok(!$schema->pg_deploy->diff->has_changes,
    'precondition: the installed schema is what its classes declare');

  $dbh->do($_) for (
    'CREATE SCHEMA old_ns',
    q{CREATE TYPE old_ns.mood AS ENUM ('ok', 'bad')},
    q{CREATE FUNCTION old_ns.touch() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RETURN NEW; END'},
    'CREATE TABLE old_ns.gone (id serial PRIMARY KEY, m old_ns.mood, n integer)',
    'CREATE INDEX gone_n_idx ON old_ns.gone (n)',
    'CREATE TRIGGER gone_trg BEFORE UPDATE ON old_ns.gone FOR EACH ROW EXECUTE FUNCTION old_ns.touch()',
    'ALTER TABLE old_ns.gone ENABLE ROW LEVEL SECURITY',
    'CREATE POLICY gone_pol ON old_ns.gone USING (n > 0)',
  );

  my $statements = applies_and_settles('an undeclared schema with table, index, trigger, policy, function and type', $schema);

  comes_before($statements, qr/^DROP TABLE old_ns\.gone;/, qr/^DROP SCHEMA old_ns;/,
    'the table is dropped before its schema');
  comes_before($statements, qr/^DROP TRIGGER gone_trg ON old_ns\.gone;/, qr/^DROP TABLE old_ns\.gone;/,
    'the trigger before its table');
  comes_before($statements, qr/^DROP TABLE old_ns\.gone;/, qr/^DROP TYPE old_ns\.mood;/,
    'the table before the type its column has');

  my ($left) = $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname = 'old_ns'});
  is($left, 0, 'the schema is gone');
  keep_is_intact('undeclared schema', $dbh);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# Two things that go together, one hanging on the other
# ---------------------------------------------------------------------------

my @PAIRS = (
  [ t93col => 'a column and the index on it', [
      'ALTER TABLE public.keep ADD COLUMN b integer',
      'CREATE INDEX keep_b_idx ON public.keep (b)',
    ],
    qr/^DROP INDEX public\.keep_b_idx;/, qr/^ALTER TABLE public\.keep DROP COLUMN b;/,
  ],
  [ t93enum => 'a column and the enum type it has', [
      q{CREATE TYPE public.mood AS ENUM ('ok', 'bad')},
      'ALTER TABLE public.keep ADD COLUMN m public.mood',
    ],
    qr/^ALTER TABLE public\.keep DROP COLUMN m;/, qr/^DROP TYPE public\.mood;/,
  ],
  [ t93trg => 'a trigger and the function it calls', [
      q{CREATE FUNCTION public.touch() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RETURN NEW; END'},
      'CREATE TRIGGER keep_trg BEFORE UPDATE ON public.keep FOR EACH ROW EXECUTE FUNCTION public.touch()',
    ],
    qr/^DROP TRIGGER keep_trg ON public\.keep;/, qr/^DROP FUNCTION public\.touch\(\);/,
  ],
  [ t93fnty => 'a function and the type it takes', [
      q{CREATE TYPE public.mood AS ENUM ('ok', 'bad')},
      q{CREATE FUNCTION public.is_ok(public.mood) RETURNS boolean LANGUAGE sql AS $$ SELECT $1 = 'ok' $$},
    ],
    qr/^DROP FUNCTION public\.is_ok\(public\.mood\);/, qr/^DROP TYPE public\.mood;/,
  ],
  # The index of the declared table has moved to a table of its own that the
  # schema does not declare: one index by schema and name, to be dropped and
  # created again -- before DROP TABLE ... CASCADE takes it.
  [ t93idx => 'an index name held by a table that goes', [
      'DROP INDEX public.keep_a_idx',
      'CREATE TABLE public.old_tab (a integer)',
      'CREATE INDEX keep_a_idx ON public.old_tab (a)',
    ],
    qr/^CREATE INDEX keep_a_idx ON public\.keep /, qr/^DROP TABLE public\.old_tab;/,
  ],
);

for my $pair (@PAIRS) {
  my ($tag, $label, $sql, $first, $then) = @$pair;
  my ($schema, $dbh) = database_with($tag => 'T93::Keep', @$sql);

  my $statements = applies_and_settles($label, $schema);
  comes_before($statements, $first, $then, "$label: in the order the server accepts");
  keep_is_intact($label, $dbh);
  $schema->storage->disconnect;
}

# An extension and a column of a type it brings, with an index in one of its
# operator classes.
SKIP: {
  skip 'pgvector (CREATE EXTENSION vector) not available on the server', 8
    unless $available{vector};

  my $label = 'an extension, a column of its type and an index in its operator class';
  my ($schema, $dbh) = database_with(t93ext => 'T93::Keep',
    'CREATE EXTENSION vector',
    'ALTER TABLE public.keep ADD COLUMN v vector(3)',
    'CREATE INDEX keep_v_idx ON public.keep USING hnsw (v vector_l2_ops)',
  );

  my $statements = applies_and_settles($label, $schema);
  comes_before($statements, qr/^ALTER TABLE public\.keep DROP COLUMN v;/, qr/^DROP EXTENSION vector;/,
    "$label: the column goes before the extension");
  keep_is_intact($label, $dbh);
  my ($left) = $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_extension WHERE extname = 'vector'});
  is($left, 0, "$label: the extension is gone");
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# k108: extensions that depend on one another
# ---------------------------------------------------------------------------
SKIP: {
  skip 'postgis and postgis_topology not available on the server', 14
    unless $available{postgis} && $available{postgis_topology};

  my $schema = T93::Bare->connect(PrivatePgDatabase->create('t93gis'), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for 'CREATE EXTENSION postgis', 'CREATE EXTENSION postgis_topology';

  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  is_deeply($model->{extensions}{postgis_topology}{requires}, ['postgis'],
    'the model carries what the catalog records: postgis_topology requires postgis');
  is_deeply($model->{extensions}{postgis}{requires}, [],
    '... and postgis requires nothing');

  my $statements = applies_and_settles('postgis and postgis_topology, neither declared', $schema);
  is_deeply($statements, [
    'DROP EXTENSION postgis_topology;',
    'DROP EXTENSION postgis;',
    'DROP SCHEMA topology;',
  ], 'the dependent extension is dropped first, the schema it was installed in last');

  # The other direction, with a schema that declares both: the schema
  # postgis_topology is installed in is created ahead of it (k106).
  my $declared = T93::Postgis->connect(PrivatePgDatabase->create('t93gis2'), @CONNECT);
  $statements = applies_and_settles('postgis and postgis_topology, both declared', $declared);
  is_deeply($statements, [
    'CREATE SCHEMA topology;',
    'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;',
    'CREATE EXTENSION IF NOT EXISTS postgis_topology;',
  ], 'the schema first, then the required extension, then the one requiring it '
   . '(postgis_topology: its control file fixes topology, so no clause)');

  $_->storage->disconnect for $schema, $declared;
}

# ---------------------------------------------------------------------------
# DROP SCHEMA ... CASCADE under an extension that stays
# ---------------------------------------------------------------------------
SKIP: {
  skip 'pgvector (CREATE EXTENSION vector) not available on the server', 6
    unless $available{vector};

  my ($schema, $dbh) = database_with(t93cas => 'T93::KeepVector');
  $dbh->do($_) for (
    'DROP EXTENSION vector',
    'CREATE SCHEMA ext',
    'CREATE EXTENSION vector WITH SCHEMA ext',
    'ALTER TABLE public.keep ADD COLUMN v ext.vector(3)',
  );
  my $has_vector = sub {
    my ($found) = $dbh->selectrow_array(
      q{SELECT count(*) FROM pg_catalog.pg_extension WHERE extname = 'vector'});
    return $found;
  };

  # What the refusal is about, shown on the server and rolled back.
  $dbh->begin_work;
  $dbh->do('DROP SCHEMA ext CASCADE');
  my $after_cascade = $has_vector->();
  $dbh->rollback;
  is($after_cascade, 0,
    'precondition: DROP SCHEMA ... CASCADE takes the extension installed in the schema with it');

  my $deploy = $schema->pg_deploy;
  # The extension is declared without a schema and the database holds it in
  # ext: the temporary database holds it there too (karr k144), so the target
  # has the schema and the diff has no DROP SCHEMA to refuse. What the
  # precondition shows -- the cascade would take the extension -- is kept by
  # the diff not writing it.
  my $diff = eval { $deploy->diff };
  ok($diff, 'the diff is built: the schema a declared extension is installed in stays') or diag $@;
  unlike($diff ? $diff->as_sql : '', qr/DROP SCHEMA ext\b|DROP EXTENSION vector\b/,
    '... and writes neither the DROP SCHEMA nor the DROP EXTENSION');
  is($has_vector->(), 1, 'the extension is still there');

  # Out of the schema, the extension is no obstacle any more.
  $dbh->do('ALTER EXTENSION vector SET SCHEMA public');
  my $statements = applies_and_settles('the schema once the extension has moved out', $schema);
  is($has_vector->(), 1, 'the extension outlives the schema it was in');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# k107: what PostgreSQL makes as part of another object is not an object of
# the schema's own
# ---------------------------------------------------------------------------
{
  my $dbh = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create('t93part') ], attrs => { PrintWarn => 0 });
  $dbh->do('SET client_min_messages = warning');
  my $model = sub { DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model };

  my $empty = $model->();

  $dbh->do($_) for (
    'CREATE TYPE public.span AS RANGE (SUBTYPE = float8)',
    q{CREATE FUNCTION public.span_len(public.span) RETURNS float8 LANGUAGE sql AS $$ SELECT upper($1) - lower($1) $$},
  );
  my $typed = $model->();

  $dbh->do(
    'CREATE TABLE public.own_tab (
       id serial PRIMARY KEY,
       ident integer GENERATED ALWAYS AS IDENTITY,
       s public.span
     )');

  # The constructor functions of a range type and of its multirange type are
  # internal parts of the type (pg_depend, deptype i).
  my $constructors = $dbh->selectcol_arrayref(q{
    SELECT p.oid::pg_catalog.regprocedure::text
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_depend d
      ON d.classid = 'pg_catalog.pg_proc'::pg_catalog.regclass AND d.objid = p.oid
    WHERE d.deptype = 'i'
      AND d.refclassid = 'pg_catalog.pg_type'::pg_catalog.regclass
      AND d.refobjid IN ('public.span'::pg_catalog.regtype, 'public.span_multirange'::pg_catalog.regtype)
    ORDER BY 1});
  cmp_ok(scalar @$constructors, '>=', 5,
    'precondition: the range type came with constructor functions, for its multirange type too')
    or diag explain $constructors;
  throws_ok { $dbh->do('DROP FUNCTION public.span(double precision, double precision)') }
    qr/because type span requires it/,
    'precondition: PostgreSQL does not let such a function be dropped';

  my $with = $model->();
  is($with->{types}{'public.span'}{type_kind}, 'range', 'the range type is in the model');
  is_deeply(
    [ sort keys %{ $with->{functions} } ],
    [ 'public.span_len(public.span)' ],
    'its constructors are not, the function the schema made itself is',
  );

  # A sequence that belongs to a column is reported with its table, whether
  # the column is serial (deptype a) or an identity column (deptype i).
  is_deeply(
    { map { $_ => [ @{ $with->{sequences}{$_} }{qw( owned_by_table owned_by_column )} ] }
      sort keys %{ $with->{sequences} } },
    {
      'public.own_tab_id_seq'    => [ 'public.own_tab', 'id' ],
      'public.own_tab_ident_seq' => [ 'public.own_tab', 'ident' ],
    },
    'the sequences of an own table are in the model, each with the column it belongs to',
  );

  # Dropping it all: DROP TYPE takes the constructors, nothing names them.
  my $drop = DBIO::PostgreSQL::Diff->new(source => $with, target => $empty);
  note $drop->as_sql;
  is_deeply(
    [ split /\n/, $drop->as_sql ],
    [
      'DROP TABLE public.own_tab;',
      'DROP FUNCTION public.span_len(public.span);',
      'DROP TYPE public.span;',
    ],
    'an undeclared range type is dropped as the one type it is',
  );
  lives_ok { $dbh->begin_work; $dbh->do($_) for split /\n/, $drop->as_sql; $dbh->commit }
    'and the drop applies' or eval { $dbh->rollback };
  is_deeply($model->(), $empty, 'nothing is left of it');

  # And back: CREATE TYPE makes the constructors, nothing creates them twice.
  my $create = DBIO::PostgreSQL::Diff->new(source => $empty, target => $typed);
  note $create->as_sql;
  is_deeply(
    [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ $create->operations } ],
    [ 'Type create', 'Function create' ],
    'creating a range type is one CREATE TYPE; the only function is the schema\'s own',
  );
  lives_ok { $dbh->begin_work; $dbh->do($_->as_sql) for @{ $create->operations }; $dbh->commit }
    'and the create applies' or eval { $dbh->rollback };
  is_deeply($model->(), $typed, 'the type and the function are back as they were');

  $dbh->disconnect;
}

done_testing;
