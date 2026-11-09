use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Extension;
use DBIO::PostgreSQL::Util qw(connection_search_path);

# OFFLINE test: what the declared extensions want of a new connection (ADR
# 0066: activation) and the storage layers their classes name.
#
# WHY: the search_path of a connection has one owner, the driver; the
# extensions give data (a library to LOAD, schemas for the path) and the driver
# composes it -- the namespace of the connection first, then the schemas the
# declaration names, then the extensions' entries. The same statements have to
# reach the sync connection and every connection of an async pool, and an
# extension that names a storage layer must get it registered, without the
# extension ever choosing the driver.
#
# What this file claims:
#   1. the rule: namespace, declaration schemas, activation entries, each
#      schema once at its first place;
#   2. a schema without extensions, with a plain extension, or with an
#      extension without activation is sent what it was sent before;
#   3. LOAD per library and the path, with and without a namespace, in name
#      order of the extensions, deduplicated; the same on the sync connection
#      and on a pool connection;
#   4. what cannot be composed (two libraries for one name) refuses;
#   5. the driver assertion is checked when the connection is set up, not at
#      connect;
#   6. a storage layer named by a declared extension is registered at
#      connection, de-duplicated, and the driver stays the PostgreSQL one; an
#      undeclared extension registers nothing.
#
# THE SUBSTITUTIONS: no server -- as t/129: a handle that logs do(), the pool
# connection is the runner core hands the statements to.

# --- 1. the rule ------------------------------------------------------------
is_deeply [ connection_search_path('ns', [], {}) ], [qw( ns public )], 'no extension: public follows the namespace';
is_deeply [ connection_search_path('ns', ['x'], {}, []) ], [qw( ns public )], 'an empty activation changes nothing';
is_deeply [ connection_search_path('ns', ['x'], {}, ['ag_catalog']) ], [qw( ns public ag_catalog )],
  'the activation comes behind the schemas of the declaration';
is_deeply [ connection_search_path('ns', ['x'], { x => 'ext' }, ['ext', 'ag_catalog', 'ns', 'ag_catalog']) ],
  [qw( ns ext ag_catalog )], 'every schema once, at its first place';

{
  package T146::Age;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'age' }
  sub driver { 'DBIO::PostgreSQL' }
  sub activation { { load => 'age', search_path => ['ag_catalog'] } }
  sub storage_layer { 'T146::AgeLayer' }

  package T146::Gis;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'postgis' }
  sub driver { 'DBIO::PostgreSQL' }
  sub activation { { search_path => [ 'gis', 'ag_catalog' ] } }

  package T146::Quiet;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'quiet' }
  sub driver { 'DBIO::PostgreSQL' }

  package T146::AgeClash;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'age_clash' }
  sub driver { 'DBIO::PostgreSQL' }
  sub activation { { load => { age => 'age_other' } } }

  package T146::Foreign;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'foreign' }
  sub driver { 'DBIO::MySQL' }
  sub activation { { load => 'foreign' } }

  package T146::AgeLayer;
  sub t146_cypher { 'cypher' }

  package T146::Handle;
  sub new { bless { log => [] }, $_[0] }
  sub do  { push @{ $_[0]{log} }, $_[1]; '0E0' }
  # karr k142: the fake server knows no control file (answers no rows), so an
  # extension without a declared schema stands for public here
  sub selectall_arrayref { [] }
}
$INC{"T146/$_.pm"} = __FILE__ for qw( Age Gis Quiet AgeClash Foreign AgeLayer );

my @LOGIN = ('dbi:Pg:dbname=k136_offline', 'u', 'p');
my $n = 0;
sub schema_class {
  my (@extensions) = @_;
  my $pkg = 'T146::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_extensions(@extensions) if @extensions;
  return $pkg;
}

sub sync_setup {
  my ($schema) = @_;
  my $storage = $schema->storage;
  my $handle  = T146::Handle->new;
  $storage->_dbh($handle);
  $storage->_conn_pid($$);
  local $storage->{_in_do_block} = 1;
  my $ok  = eval { $storage->_run_connection_actions; 1 };
  my $err = $@;
  $storage->_dbh(undef);
  return $ok ? $handle->{log} : "died: $err";
}

sub pool_setup {
  my ($schema) = @_;
  my @sent;
  return "died: $@"
    unless eval { $schema->storage->_run_pool_connect_actions(sub {
        return [] if $_[0] =~ /pg_available_extension_versions/;   # the control-schema question (karr k142)
        push @sent, $_[0];
      }); 1 };
  return \@sent;
}

sub both {
  my ($class, $want, $name, %attrs) = @_;
  my $schema = $class->connect(@LOGIN, { %attrs });
  my $got = sync_setup($schema);
  is_deeply $got, $want, "$name (sync)" or diag explain $got;
  $schema = $class->connect(@LOGIN, { %attrs });
  $got = pool_setup($schema);
  is_deeply $got, $want, "$name (pool connection)" or diag explain $got;
}

my $age = { class => 'T146::Age' };
my $gis = { class => 'T146::Gis' };

# --- 2. as before --------------------------------------------------------------
both(schema_class(), [], 'no extension, no key: nothing is sent');
both(schema_class(), ['SET search_path TO tenant_a, public'], 'no extension, with the key: as before', schema => 'tenant_a');
both(schema_class('citext'), [], 'a plain extension, no key: nothing is sent');
both(schema_class('citext', quiet => { class => 'T146::Quiet' }),
  ['SET search_path TO tenant_a, public'], 'plain and quiet extensions: as before', schema => 'tenant_a');
both(schema_class(vector => { schema => 'extensions' }),
  ['SET search_path TO tenant_a, extensions'], 'the schema of the declaration stays', schema => 'tenant_a');

# --- 3. LOAD and the path --------------------------------------------------------
both(schema_class(age => $age), [
  q{LOAD 'age'},
  'SET search_path TO tenant_a, public, ag_catalog',
], 'age with a namespace: LOAD, then the path with the entry behind public', schema => 'tenant_a');

both(schema_class(postgis => $gis, age => $age), [
  q{LOAD 'age'},
  'SET search_path TO tenant_a, public, ag_catalog, gis',
], 'age and postgis: entries in the name order of the extensions, ag_catalog once', schema => 'tenant_a');
both(schema_class(age => $age, postgis => $gis), [
  q{LOAD 'age'},
  'SET search_path TO tenant_a, public, ag_catalog, gis',
], '... whatever the order of the declaration', schema => 'tenant_a');

both(schema_class(postgis => { class => 'T146::Gis', schema => 'gis' }, age => { class => 'T146::Age', schema => 'ag_catalog' }), [
  q{LOAD 'age'},
  'SET search_path TO tenant_a, gis, ag_catalog',
], 'the schemas of the declaration come first, the entries behind them, deduplicated', schema => 'tenant_a');

both(schema_class(age => $age), [
  q{LOAD 'age'},
  q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || ', ag_catalog', false)},
], 'without a namespace: LOAD, and the entries appended to the path the connection has');

both(schema_class(postgis => { class => 'T146::Gis' }), [
  q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || ', gis, ag_catalog', false)},
], 'an activation with only a path: no LOAD');

both(schema_class(age => $age), [
  q{LOAD 'age'},
  'SET search_path TO "Tenant A", public, ag_catalog',
  'SET TIME ZONE UTC',
], 'names are written as identifiers; the connect actions of the application come behind',
  schema => 'Tenant A', on_connect_do => ['SET TIME ZONE UTC']);

# --- 4. cannot compose --------------------------------------------------------------
{
  my $schema = schema_class(age => $age, age_clash => { class => 'T146::AgeClash' })->connect(@LOGIN, { schema => 'ns' });
  like sync_setup($schema), qr/Activation cannot compose: 'age' is loaded from 'age' by age and from 'age_other' by age_clash/,
    'two libraries for one name refuse';
}

# --- 5. the driver assertion ------------------------------------------------------------
{
  my $schema;
  lives_ok { $schema = schema_class(foreign => { class => 'T146::Foreign' })->connect(@LOGIN, { schema => 'ns' }) }
    'connect does not check the driver assertion: a class of another driver does not stop it';
  like sync_setup($schema), qr/Extension 'foreign' \(T146::Foreign\) belongs to the driver DBIO::MySQL, but the schema's driver is DBIO::PostgreSQL/,
    '... the first use of the connection refuses, naming both drivers';
}
{
  local $DBIO::PostgreSQL::Extension::FAMILY{ghost} = [ 'T146::Ghost', 'DBIO-T146-Ghost' ];
  throws_ok { schema_class('ghost')->connect(@LOGIN) }
    qr/class T146::Ghost is not installed -- install the distribution DBIO-T146-Ghost/,
    'a distribution that is not installed refuses when the layers are registered, naming it';
}

# --- 6. the storage layer ---------------------------------------------------------------------
{
  my $class = schema_class(age => $age);
  is_deeply $class->storage_layers, [], 'declaring registers nothing yet';
  my $schema = $class->connect(@LOGIN);
  is_deeply $schema->storage_layers, ['T146::AgeLayer'], 'connect registers the layer the class names';
  isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage', 'the storage: the driver stays the PostgreSQL one';
  ok $schema->storage->can('t146_cypher'), '... with the layer composed over it';
  is_deeply $class->storage_layers, [], 'the class itself is not changed by a connect';

  $schema->connection(@LOGIN);
  is_deeply $schema->storage_layers, ['T146::AgeLayer'], 'connecting again registers it once';
}
{
  my $schema = schema_class('citext', postgis => $gis)->connect(@LOGIN);
  is_deeply $schema->storage_layers, [], 'extensions that name no layer register none';
  $schema = schema_class()->connect(@LOGIN);
  is_deeply $schema->storage_layers, [], 'a schema without extensions neither';
}

done_testing;
