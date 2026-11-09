use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k84 -- what an installed extension owns belongs to the extension, not
# to the schema. k81 (t/66) taught that to the functions; this is every other
# kind of object the introspection reads and an extension can own: schemas,
# enum/composite/range types, sequences, tables, views, materialized views.
# Reported as schema objects, they made a diff against a schema that does not
# declare the extension emit DROP EXTENSION followed by a DROP for each of
# them -- already gone with the extension, so apply died -- and the other
# direction CREATE EXTENSION followed by a CREATE for what it had just made.
#
# A member table takes what hangs on it out of the model with it: columns,
# indexes, CHECK constraints, foreign keys, triggers, policies. None of those
# is a member of its own (PostgreSQL records no pg_depend row of deptype e
# for them), so with only the table left out they would stay behind as
# entries for a table the model no longer has -- and the index, trigger and
# policy diffs would drop them one by one.
#
# Part one makes objects of every kind members of an extension by hand
# (ALTER EXTENSION ... ADD writes exactly the pg_depend row CREATE EXTENSION
# writes), so it does not depend on what a given extension version ships.
# Next to each member stands an object of the same kind the schema owns: it
# must still be reported, or an empty model would pass. Part two runs real
# extensions through Deploy->diff and ->apply.
#
# Every database here is private: extensions are installed and dropped.

my %available;
{
  my $h = LiveServer->control_dbh;
  %available = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions}
  ) };
  $h->disconnect;
}
plan skip_all => 'pgvector (CREATE EXTENSION vector) not available on the server'
  unless $available{vector};

sub connect_private {
  my ($tag) = @_;
  my @private = PrivatePgDatabase->create($tag);
  my $dbh = LiveServer->control_dbh(login => \@private, attrs => { PrintWarn => 0 });
  $dbh->do('SET client_min_messages = warning');
  return ($dbh, @private);
}

# ---------------------------------------------------------------------------
# Part one: one member and one own object of every kind
# ---------------------------------------------------------------------------

my ($dbh) = connect_private('t86');

$dbh->do($_) for (
  'CREATE EXTENSION vector',

  ( map { (
    "CREATE SCHEMA k84_${_}_ns",
    "CREATE TYPE public.k84_${_}_enum AS ENUM ('a', 'b')",
    "CREATE TYPE public.k84_${_}_comp AS (x integer, y integer)",
    "CREATE TYPE public.k84_${_}_range AS RANGE (SUBTYPE = float8)",
    "CREATE SEQUENCE public.k84_${_}_seq",
    "CREATE TABLE public.k84_${_}_tab (
       id serial PRIMARY KEY, ident integer GENERATED ALWAYS AS IDENTITY,
       n integer, other_id integer,
       CONSTRAINT k84_${_}_chk CHECK (n > 0)
     )",
    "CREATE INDEX k84_${_}_idx ON public.k84_${_}_tab (n)",
    "CREATE VIEW public.k84_${_}_view AS SELECT 1 AS one",
    "CREATE MATERIALIZED VIEW public.k84_${_}_mv AS SELECT 1 AS one",
    "CREATE INDEX k84_${_}_mv_idx ON public.k84_${_}_mv (one)",
  ) } qw(own ext) ),

  q{CREATE FUNCTION public.k84_trg() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RETURN NEW; END'},

  # Each table points at the other, so the model has a foreign key ON the
  # member table (goes with it) and one TO it from the own table (stays).
  'ALTER TABLE public.k84_own_tab ADD CONSTRAINT k84_own_fk
     FOREIGN KEY (other_id) REFERENCES public.k84_ext_tab (id)',
  'ALTER TABLE public.k84_ext_tab ADD CONSTRAINT k84_ext_fk
     FOREIGN KEY (other_id) REFERENCES public.k84_own_tab (id)',

  ( map { (
    "CREATE TRIGGER k84_${_}_trg BEFORE UPDATE ON public.k84_${_}_tab
       FOR EACH ROW EXECUTE FUNCTION public.k84_trg()",
    "CREATE POLICY k84_${_}_pol ON public.k84_${_}_tab USING (n > 0)",
  ) } qw(own ext) ),

  'ALTER EXTENSION vector ADD SCHEMA k84_ext_ns',
  'ALTER EXTENSION vector ADD TYPE public.k84_ext_enum',
  'ALTER EXTENSION vector ADD TYPE public.k84_ext_comp',
  'ALTER EXTENSION vector ADD TYPE public.k84_ext_range',
  'ALTER EXTENSION vector ADD SEQUENCE public.k84_ext_seq',
  'ALTER EXTENSION vector ADD TABLE public.k84_ext_tab',
  'ALTER EXTENSION vector ADD VIEW public.k84_ext_view',
  'ALTER EXTENSION vector ADD MATERIALIZED VIEW public.k84_ext_mv',
);

# True if the object is a member of an extension: the pg_depend row the
# introspection goes by, read here independently of it.
sub is_member {
  my ($catalog, $reg, $name) = @_;
  my ($member) = $dbh->selectrow_array(qq{
    SELECT 1 FROM pg_catalog.pg_depend d
    WHERE d.classid = 'pg_catalog.$catalog'::pg_catalog.regclass
      AND d.objid = ?::pg_catalog.$reg
      AND d.deptype = 'e'
  }, undef, $name);
  return $member ? 1 : 0;
}

my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;

# kind, model section, catalog of the pg_depend row, reg* cast, name with a
# %s for own/ext. Schemas are keyed by bare name, everything else by
# schema.name.
my @KINDS = (
  [ 'schema',            'schemas',   'pg_namespace', 'regnamespace', 'k84_%s_ns'           ],
  [ 'enum type',         'types',     'pg_type',      'regtype',      'public.k84_%s_enum'  ],
  [ 'composite type',    'types',     'pg_type',      'regtype',      'public.k84_%s_comp'  ],
  [ 'range type',        'types',     'pg_type',      'regtype',      'public.k84_%s_range' ],
  [ 'sequence',          'sequences', 'pg_class',     'regclass',     'public.k84_%s_seq'   ],
  [ 'table',             'tables',    'pg_class',     'regclass',     'public.k84_%s_tab'   ],
  [ 'view',              'tables',    'pg_class',     'regclass',     'public.k84_%s_view'  ],
  [ 'materialized view', 'tables',    'pg_class',     'regclass',     'public.k84_%s_mv'    ],
);

for my $kind (@KINDS) {
  my ($label, $section, $catalog, $reg, $name) = @$kind;
  my ($own, $ext) = map { sprintf $name, $_ } qw(own ext);

  subtest "$label owned by an extension is not a schema object" => sub {
    ok( is_member($catalog, $reg, $ext), "precondition: $ext is a member of the extension");
    ok(!is_member($catalog, $reg, $own), "precondition: $own is not");

    ok( exists $model->{$section}{$own}, "the schema's own $label is reported");
    ok(!exists $model->{$section}{$ext}, "the extension's $label is not");
  };
}

# What hangs on a relation, by model section: the relations that have such
# entries. A member relation's entries go with it, the own one's stay.
my %DEPENDENT = (
  columns           => [qw( tab view mv )],
  indexes           => [qw( tab mv )],
  check_constraints => [qw( tab )],
  foreign_keys      => [qw( tab )],
  triggers          => [qw( tab )],
  policies          => [qw( tab )],
);

for my $section (sort keys %DEPENDENT) {
  subtest "$section of a relation owned by an extension go with it" => sub {
    for my $rel (@{ $DEPENDENT{$section} }) {
      ok( exists $model->{$section}{"public.k84_own_$rel"},
        "$section of the schema's own k84_own_$rel are reported");
      ok(!exists $model->{$section}{"public.k84_ext_$rel"},
        "$section of the extension's k84_ext_$rel are not");
    }
  };
}

subtest 'a foreign key from an own table to a member table stays' => sub {
  my $fks = $model->{foreign_keys}{'public.k84_own_tab'} || [];
  is_deeply(
    [ map { "$_->{constraint_name} -> $_->{remote_schema}.$_->{remote_table}" } @$fks ],
    [ 'k84_own_fk -> public.k84_ext_tab' ],
    'the constraint is on the own table, so it is the schema\'s',
  );
};

# What PostgreSQL made along with a member. ALTER EXTENSION ... ADD writes the
# member row for the object it names only -- not for the sequence behind a
# serial or identity column (deptype a, or i, on the column) and not for the
# constructor functions of a range type (deptype i on the type). An
# extension's script makes each of them a member in its own right, which is
# why no installed extension shows this (postgis_topology and
# postgis_tiger_geocoder own their sequences); a database where membership
# was assigned afterwards does. Neither is the schema's (karr k107): the
# sequence goes where its table goes, and a constructor is part of its type
# -- for the schema's own range types just the same, t/93.
for my $column (qw( id ident )) {
  ok(exists $model->{sequences}{"public.k84_own_tab_${column}_seq"},
    "the sequence of the schema's own table, column $column, is reported");
  ok(!exists $model->{sequences}{"public.k84_ext_tab_${column}_seq"},
    "the sequence of the member table, column $column, is not");
}
is_deeply(
  [ sort grep { /^public\.k84_(?:own|ext)_(?:multi)?range\(/ } keys %{ $model->{functions} } ],
  [],
  'no constructor function of a range type is reported, the member\'s or the schema\'s own',
);

$dbh->disconnect;

# ---------------------------------------------------------------------------
# Part two: real extensions through Deploy->diff and ->apply
# ---------------------------------------------------------------------------

{
  package K84::Bare;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package K84::WithPostgis;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  # postgis and age are in the driver's table of the family (ADR 0066), whose
  # distributions are no dependency of this one: the plain class stands in, so
  # what is measured here stays the driver's own handling of an extension.
  __PACKAGE__->pg_extensions(postgis => { class => 'DBIO::PostgreSQL::Extension' });
}
{
  package K84::WithRepack;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('pg_repack');
}
{
  package K84::WithAge;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions(age => { class => 'DBIO::PostgreSQL::Extension' });
}

# "Kind action" of every op, e.g. "Extension drop".
sub op_kinds {
  my ($diff) = @_;
  return [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ $diff->operations } ];
}

# Number of members of $ext matching $where, a condition on the member's
# catalog row (alias o).
sub member_count {
  my ($h, $ext, $catalog, $where) = @_;
  my ($count) = $h->selectrow_array(qq{
    SELECT count(*)
    FROM pg_catalog.pg_depend d
    JOIN pg_catalog.pg_extension e ON e.oid = d.refobjid
    JOIN pg_catalog.$catalog o ON o.oid = d.objid
    WHERE d.classid = 'pg_catalog.$catalog'::pg_catalog.regclass
      AND d.deptype = 'e'
      AND e.extname = ?
      AND $where
  }, undef, $ext);
  return $count;
}

# A database that has $ext plus one table of the schema's own, diffed against
# a schema that does not declare the extension and then against one that
# does. $precondition checks that the extension really brings the kinds of
# member this case is here for.
sub extension_roundtrip {
  my ($ext, $with_class, $precondition) = @_;

  my ($h, @private) = connect_private("t86_$ext");
  $h->do(qq{CREATE EXTENSION "$ext"});
  $h->do('CREATE TABLE public.k84_own_place (id integer PRIMARY KEY, n integer CHECK (n > 0))');
  $precondition->($h);

  subtest "$ext: dropping the undeclared extension drops it, not what it owns" => sub {
    my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K84::Bare->connect(@private));
    my $diff = $deploy->diff;

    # The table first: drops come in the reverse of the order of dependency,
    # and a table may use what an extension brings (karr k108, t/92).
    is_deeply(op_kinds($diff), [ 'Table drop', 'Extension drop' ],
      'one DROP EXTENSION, and the only other op drops the own table');
    like($diff->as_sql, qr/DROP TABLE public\.k84_own_place;/,
      'the own table is the one dropped');

    lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'apply lives (it drops the undeclared extension and its table)';
    my ($still) = $h->selectrow_array(
      q{SELECT 1 FROM pg_catalog.pg_extension WHERE extname = ?}, undef, $ext);
    ok(!$still, 'extension is gone');
    ok(!$deploy->diff->has_changes, 'nothing left to change once it is gone');
  };

  subtest "$ext: adding the declared extension creates it, not what it owns" => sub {
    # Its own starting point, whatever the subtest above left behind.
    $h->do(qq{DROP EXTENSION IF EXISTS "$ext"});
    $h->do('DROP TABLE IF EXISTS public.k84_own_place');

    my $deploy = DBIO::PostgreSQL::Deploy->new(schema => $with_class->connect(@private));
    my $diff = $deploy->diff;

    is_deeply(op_kinds($diff), [ 'Extension create' ],
      'the only op is CREATE EXTENSION');

    lives_ok { $deploy->apply($diff) } 'apply lives';
    ok(!$deploy->diff->has_changes, 'nothing left to change once the extension is in');
  };

  $h->disconnect;
}

# PostGIS owns a table with a primary key and a CHECK constraint
# (spatial_ref_sys), two views (geometry_columns, geography_columns) and
# composite types (geometry_dump, valid_detail).
SKIP: {
  skip 'postgis not available on the server', 2 unless $available{postgis};

  extension_roundtrip(postgis => 'K84::WithPostgis', sub {
    my ($h) = @_;
    ok(member_count($h, 'postgis', 'pg_class', q{o.relkind = 'r'}),
      'precondition: postgis owns a table');
    ok(member_count($h, 'postgis', 'pg_class', q{o.relkind = 'v'}),
      'precondition: postgis owns views');
    ok(member_count($h, 'postgis', 'pg_type',
        q{o.typtype = 'c' AND EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                                      WHERE c.oid = o.typrelid AND c.relkind = 'c')}),
      'precondition: postgis owns composite types');
    my ($pkey) = $h->selectrow_array(q{
      SELECT count(*) FROM pg_catalog.pg_index
      WHERE indrelid = 'public.spatial_ref_sys'::pg_catalog.regclass});
    ok($pkey, 'precondition: its table has an index');
  });
}

# pg_repack's script creates its schema (repack), which makes the schema a
# member.
SKIP: {
  skip 'pg_repack not available on the server', 2 unless $available{pg_repack};

  extension_roundtrip(pg_repack => 'K84::WithRepack', sub {
    my ($h) = @_;
    ok(member_count($h, 'pg_repack', 'pg_namespace', q{o.nspname = 'repack'}),
      'precondition: pg_repack owns its schema');
  });
}

# Not every schema an extension brings is its member. One CREATE EXTENSION
# itself creates because the control file names it (age: "schema =
# ag_catalog", postgis_topology: topology) is not: the extension depends on
# the schema, not the other way round, and DROP EXTENSION leaves it behind.
# The exclusion does not reach it, and need not: it is a schema like any
# other, which the diff creates and drops. What it takes is the order (karr
# k106) -- the schema ahead of the extension, CREATE SCHEMA ag_catalog and
# then CREATE EXTENSION age, which uses a schema that is there; the other way
# round CREATE SCHEMA finds the schema the extension has just made and apply
# dies. Dropping goes in reverse, DROP EXTENSION age ahead of DROP SCHEMA
# ag_catalog CASCADE.
SKIP: {
  skip 'age not available on the server', 11 unless $available{age};

  my ($h, @private) = connect_private('t86_age');
  my $has_ag_catalog = sub {
    my ($found) = $h->selectrow_array(
      q{SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'ag_catalog'});
    return $found;
  };

  $h->do('CREATE EXTENSION age');
  ok($has_ag_catalog->()
      && !member_count($h, 'age', 'pg_namespace', q{o.nspname = 'ag_catalog'}),
    'precondition: age comes with ag_catalog and does not own it');
  $h->do('DROP EXTENSION age');
  ok($has_ag_catalog->(), 'precondition: DROP EXTENSION leaves ag_catalog behind');
  $h->do('DROP SCHEMA ag_catalog');

  $h->do('CREATE SCHEMA ag_catalog');
  lives_ok { $h->do('CREATE EXTENSION age') }
    'precondition: CREATE EXTENSION takes a schema that is already there';
  $h->do('DROP EXTENSION age');
  $h->do('DROP SCHEMA ag_catalog');

  {
    my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K84::WithAge->connect(@private));
    my $diff = $deploy->diff;
    is_deeply(op_kinds($diff), [ 'Schema create', 'Extension create' ],
      'age: the schema is created ahead of the extension that is installed into it');
    lives_ok { $deploy->apply($diff) } 'age: adding the declared extension applies';
    ok(!$deploy->diff->has_changes, 'age: nothing left to change once the extension is in');
  }

  {
    my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K84::Bare->connect(@private));
    my $diff = $deploy->diff;
    is_deeply(op_kinds($diff), [ 'Extension drop', 'Schema drop' ],
      'age: undeclared, the extension is dropped ahead of the schema it leaves behind');
    lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'age: dropping the undeclared extension applies';
    ok(!$has_ag_catalog->(), 'age: ag_catalog is gone with it');
    ok(!$deploy->diff->has_changes, 'age: nothing left to change once it is gone');
  }

  $h->disconnect;
}

done_testing;
