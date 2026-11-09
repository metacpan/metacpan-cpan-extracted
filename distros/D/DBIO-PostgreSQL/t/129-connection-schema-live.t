use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k128: the connect key 'schema' against a real PostgreSQL.
#
#   K128L::Schema->connect($dsn, $user, $pass, { schema => 'tenant_a' })
#
# CLAIM: one schema class, which names no namespace, is installed into and
# read from as many namespaces as there are connections, and the namespace of
# each is its connect key alone:
#
#   - an install over the connection creates the namespace when it is not
#     there and puts every object into it. Nothing lands in public -- which is
#     where PostgreSQL puts an unqualified object, without a word, when the
#     first schema of the search_path does not exist;
#   - each connection reads and writes its own rows, sync and on every
#     connection of a future_io pool;
#   - an extension is the database's: it is in the schema it was declared for,
#     public where it names none, and never in the namespace -- whether the
#     install creates it or the diff does;
#   - the deploy of a connection is restricted to its namespace: the diff
#     after an install is empty, and it neither sees nor touches what another
#     namespace holds.
#
# The offline half, t/129-connection-schema.t, pins the statements; this file
# has the server say where the objects are. It installs and diffs whole
# namespaces and extensions, so it works in two databases of its own.

my @sync_db = PrivatePgDatabase->create('t129');

{
  package K128L::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    name      => { data_type => 'text' },
    embedding => { data_type => 'vector(3)', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index(idx_things_name => { columns => ['name'] });
}
{
  package K128L::Result::Note;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('notes');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    thing_id => { data_type => 'integer' },
    body     => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(thing => 'K128L::Result::Thing', 'thing_id');
  __PACKAGE__->pg_fk_constraints_from_rels(1);
}
{
  # The extension names no schema: it is the database's, in public.
  package K128L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('vector');
  __PACKAGE__->register_class(Thing => 'K128L::Result::Thing');
  __PACKAGE__->register_class(Note  => 'K128L::Result::Note');
}
{
  package K128L::Result::Word;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('words');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  # The operator class is found through the search_path, like a type.
  __PACKAGE__->pg_index(idx_words_trgm => {
    using => 'gin', columns => ['word'], opclasses => { word => 'gin_trgm_ops' },
  });
}
{
  # The extension in a schema of its own.
  package K128L::WithExtensionSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('k128_ext');
  __PACKAGE__->pg_extensions(pg_trgm => { schema => 'k128_ext' });
  __PACKAGE__->register_class(Word => 'K128L::Result::Word');
}

# --- what the server says ---------------------------------------------------

my $dbh;   # the control session of the database the helpers below ask
sub ask_database { $dbh = LiveServer->control_dbh(login => [ @_ ]) }

sub namespace_exists {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname = ?}, undef, $name);
}

# The tables of a schema.
sub tables_in {
  my ($namespace) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT c.relname FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = ? AND c.relkind = 'r' ORDER BY 1}, undef, $namespace);
}

# Every relation of a schema, of any kind: tables, indexes, sequences, views.
sub relations_in {
  my ($namespace) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT c.relname FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = ? ORDER BY 1}, undef, $namespace);
}

sub extension_schema {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT n.nspname FROM pg_catalog.pg_extension e
        JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
       WHERE e.extname = ?}, undef, $name);
}

# The schema of the table each foreign key of a schema's tables points at.
sub foreign_key_targets {
  my ($namespace) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT tn.nspname || '.' || t.relname
        FROM pg_catalog.pg_constraint k
        JOIN pg_catalog.pg_class c      ON c.oid = k.conrelid
        JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
        JOIN pg_catalog.pg_class t      ON t.oid = k.confrelid
        JOIN pg_catalog.pg_namespace tn ON tn.oid = t.relnamespace
       WHERE k.contype = 'f' AND n.nspname = ? ORDER BY 1}, undef, $namespace);
}

sub names_of { [ map { $_->name } $_[0]->resultset('Thing')->search({}, { order_by => 'name' })->all ] }

sub in_namespace {
  my ($class, $login, $namespace, %attrs) = @_;
  return $class->connect(@$login, { schema => $namespace, PrintWarn => 0, %attrs });
}

# The diff of a connection's deploy: no change, and both models hold the
# namespace alone.
sub diff_is_empty_and_restricted {
  my ($schema, $namespace, $tables) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  ok $diff, "$namespace: the diff is built" or return diag $@;
  ok !$diff->has_changes, "$namespace: no change after the install" or diag $diff->as_sql;
  my @want = map { "$namespace.$_" } @$tables;
  is_deeply [ sort keys %{ $diff->source->{tables} } ], \@want,
    "$namespace: the model of the database holds the tables of the namespace and no other";
  is_deeply [ sort keys %{ $diff->target->{tables} } ], \@want,
    "$namespace: ... and so does the model of what the class declares";
  is_deeply [ sort keys %{ $diff->source->{schemas} } ], [ $namespace ],
    "$namespace: ... of the schemas it holds this one";
  return $diff;
}

# ---------------------------------------------------------------------------
# 1. Sync: two namespaces, one class.
# ---------------------------------------------------------------------------

ask_database(@sync_db);

my $schema_a = in_namespace('K128L::Schema', \@sync_db, 'tenant_a');
my $schema_b = in_namespace('K128L::Schema', \@sync_db, 'tenant_b');

ok !namespace_exists('tenant_a') && !namespace_exists('tenant_b'),
  'neither namespace is there to begin with';
is scalar $schema_a->storage->dbh->selectrow_array('SHOW search_path'), 'tenant_a, public',
  'the connection has its namespace first in the search_path, then the schema of the extension';

# Through pg_deploy->install for one, through $schema->deploy for the other.
ok eval { $schema_a->pg_deploy->install; 1 }, 'tenant_a: install runs through' or diag $@;
ok eval { $schema_b->deploy; 1 }, 'tenant_b: $schema->deploy runs through' or diag $@;

for my $namespace (qw( tenant_a tenant_b )) {
  ok namespace_exists($namespace), "$namespace: the install created the namespace";
  is_deeply tables_in($namespace), [qw( notes things )], "$namespace: its tables are in it";
  is_deeply foreign_key_targets($namespace), [ "$namespace.things" ],
    "$namespace: its foreign key points at the table of the same namespace";
}
is_deeply relations_in('public'), [],
  'public holds no relation: nothing of either install went there';
is extension_schema('vector'), 'public',
  'the extension is in public, the schema of an extension that names none -- not in a namespace';

# Each connection writes and reads its own rows.
$schema_a->resultset('Thing')->create({ name => $_ }) for qw( a_one a_two );
$schema_b->resultset('Thing')->create({ name => 'b_one', embedding => [ 1, 2, 3 ] });
my $thing_b = $schema_b->resultset('Thing')->search({ name => 'b_one' })->single;
$schema_b->resultset('Note')->create({ thing_id => $thing_b->id, body => 'of b' });

is_deeply names_of($schema_a), [qw( a_one a_two )], 'tenant_a reads its rows and no other';
is_deeply names_of($schema_b), [qw( b_one )],       'tenant_b reads its rows and no other';
is $schema_a->resultset('Note')->count, 0, 'tenant_a has none of the notes of tenant_b';
is_deeply $thing_b->embedding, [ 1, 2, 3 ],
  'a column of the extension\'s type is written and read: its type is found through the search_path';
is scalar $dbh->selectrow_array('SELECT count(*) FROM tenant_a.things'), 2,
  'the server has the rows of tenant_a in tenant_a.things';
is scalar $dbh->selectrow_array('SELECT count(*) FROM tenant_b.things'), 1,
  '... and those of tenant_b in tenant_b.things';

# The deploy of a connection is restricted to its namespace.
diff_is_empty_and_restricted($schema_a, 'tenant_a', [qw( notes things )]);
diff_is_empty_and_restricted($schema_b, 'tenant_b', [qw( notes things )]);

$dbh->do('ALTER TABLE tenant_b.things ADD COLUMN stray text');
{
  my $diff_a = eval { $schema_a->pg_deploy->diff };
  ok $diff_a && !$diff_a->has_changes,
    'a change in tenant_b is nothing the deploy of tenant_a sees'
    or diag $@ || $diff_a->as_sql;

  my $diff_b = eval { $schema_b->pg_deploy->diff };
  my $sql_b  = $diff_b ? $diff_b->as_sql : "no diff: $@";
  like $sql_b, qr/ALTER TABLE tenant_b\.things DROP COLUMN stray/,
    '... the deploy of tenant_b does, and names the table with its namespace';
  unlike $sql_b, qr/tenant_a/, '... and no statement of it names tenant_a';

  ok eval { $schema_b->pg_deploy->upgrade(allow_destructive => 1); 1 }, 'tenant_b: upgrade runs through (it drops a stray column)' or diag $@;
  is scalar $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_attribute
       WHERE attrelid = 'tenant_b.things'::regclass AND attname = 'stray' AND NOT attisdropped}),
    0, '... and the column is gone from tenant_b.things';
  is_deeply names_of($schema_b), [qw( b_one )], '... its rows are still there';
  is_deeply names_of($schema_a), [qw( a_one a_two )], '... and so are those of tenant_a';
}
is_deeply relations_in('public'), [], 'public still holds no relation';

# An extension in a schema of its own: the search_path has that schema, and
# the extension is there.
SKIP: {
  skip 'extension pg_trgm not available on the server', 8
    unless $dbh->selectrow_array(
      q{SELECT count(*) FROM pg_catalog.pg_available_extensions WHERE name = 'pg_trgm'});

  my $schema_t = in_namespace('K128L::WithExtensionSchema', \@sync_db, 'tenant_t');
  is scalar $schema_t->storage->dbh->selectrow_array('SHOW search_path'), 'tenant_t, k128_ext',
    'an extension in a schema of its own: that schema follows the namespace, public does not';
  ok eval { $schema_t->pg_deploy->install; 1 }, 'tenant_t: install runs through' or diag $@;
  is extension_schema('pg_trgm'), 'k128_ext', 'the extension is in its declared schema';
  is_deeply tables_in('tenant_t'), [qw( words )], 'the table is in the namespace';
  is_deeply tables_in('k128_ext'), [], '... and not in the schema of the extension';
  $schema_t->resultset('Word')->create({ word => 'namespace' });
  is $schema_t->resultset('Word')->count, 1, '... and is written and read';
  my $diff = eval { $schema_t->pg_deploy->diff };
  ok $diff && !$diff->has_changes, 'tenant_t: no change after the install'
    or diag $@ || $diff->as_sql;
  is extension_schema('vector'), 'public',
    '... and the extension another class declared is left where it is';
}

$_->storage->disconnect for $schema_a, $schema_b;
$dbh->disconnect;

# ---------------------------------------------------------------------------
# 2. A database that has nothing yet: the diff creates namespace and
#    extension, and the future_io pool works in its namespace.
# ---------------------------------------------------------------------------

my @fresh_db = PrivatePgDatabase->create('t129b');
ask_database(@fresh_db);

{
  my $schema_c = in_namespace('K128L::Schema', \@fresh_db, 'tenant_c');
  ok !namespace_exists('tenant_c') && !defined extension_schema('vector'),
    'a database with neither the namespace nor the extension';

  my $diff = eval { $schema_c->pg_deploy->diff };
  my $sql  = $diff ? $diff->as_sql : "no diff: $@";
  like $sql, qr/^CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;$/m,
    'the diff creates the extension WITH SCHEMA';
  like $sql, qr/nspname = 'tenant_c'.*?CREATE SCHEMA tenant_c;/s, '... and the namespace';

  ok eval { $schema_c->pg_deploy->upgrade; 1 }, 'tenant_c: upgrade from nothing runs through' or diag $@;
  is_deeply tables_in('tenant_c'), [qw( notes things )], '... the tables are in the namespace';
  is extension_schema('vector'), 'public', '... the extension is in public, not in the namespace';
  is_deeply relations_in('public'), [], '... and public holds no relation';
  diff_is_empty_and_restricted($schema_c, 'tenant_c', [qw( notes things )]);
  $schema_c->storage->disconnect;
}

SKIP: {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or skip 'Future::IO::Impl::IOAsync, IO::Async and DBIO::Async are needed for future_io', 14;

  my %schema = map {
    $_ => in_namespace('K128L::Schema', \@fresh_db, $_, async => 'future_io', pool_size => 2, PrintError => 0)
  } qw( tenant_d tenant_e );
  my %async = map { $_ => $schema{$_}->storage->async } keys %schema;

  for my $namespace (sort keys %schema) {
    ok !namespace_exists($namespace), "$namespace: not there to begin with";
    ok eval { $async{$namespace}->deploy_async($schema{$namespace})->get; 1 },
      "$namespace: deploy_async runs through" or diag $@;
    is_deeply tables_in($namespace), [qw( notes things )], "$namespace: its tables are in it";
  }
  is_deeply relations_in('public'), [], 'public holds no relation after the future_io installs';

  # Two statements in flight: both pool connections, each with the path.
  my @path = ('pg_namespace', [ \q{current_setting('search_path')}, \'pg_backend_pid()' ],
    { nspname => 'pg_catalog' });
  for my $namespace (sort keys %schema) {
    my @rows = map { $_->get } map { $async{$namespace}->select_async(@path) } 1, 2;
    is_deeply [ map { $_->[0] } @rows ], [ ("$namespace, public") x 2 ],
      "$namespace: every pool connection has the namespace first in its search_path";
    isnt $rows[0][1], $rows[1][1], '... and they are two connections';
  }

  my $source_d = $schema{tenant_d}->source('Thing');
  my $source_e = $schema{tenant_e}->source('Thing');
  $async{tenant_d}->insert_async($source_d, { name => $_ })->get for qw( d_one d_two );
  $async{tenant_e}->insert_async($source_e, { name => 'e_one' })->get;

  my $names = sub {
    [ map { $_->[0] } $async{ $_[0] }->select_async('things', ['name'], {}, { order_by => 'name' })->get ]
  };
  is_deeply $names->('tenant_d'), [qw( d_one d_two )], 'tenant_d reads its rows and no other, on the pool';
  is_deeply $names->('tenant_e'), [qw( e_one )],       'tenant_e reads its rows and no other, on the pool';
  is scalar $dbh->selectrow_array('SELECT count(*) FROM tenant_d.things'), 2,
    'the server has the rows of tenant_d in tenant_d.things';

  $_->storage->disconnect for values %schema;
}

$dbh->disconnect;

done_testing;
