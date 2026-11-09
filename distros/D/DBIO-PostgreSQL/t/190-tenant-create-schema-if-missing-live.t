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

# LIVE test for karr k131 (d): the schemas a connection with the connect key
# schema creates are looked up in pg_namespace, and the script and the diff
# run through on a server.
#
# CLAIM: with the lookup in place the install and the first diff behave as
# they did with CREATE SCHEMA IF NOT EXISTS -- they create what is missing and
# pass over what is there (a namespace made ahead by an administrator). WHAT
# THIS DOES NOT SHOW: the point of the change, that no CREATE on the database
# is asked for a namespace that exists, needs a role without that privilege;
# the test database has only a superuser, and roles are not made here.
# Offline half: t/189-tenant-create-schema-if-missing.t.

my @db = PrivatePgDatabase->create('t190');

{
  package K131M::Result::Word;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('words');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package K131M::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('k131_ext');
  __PACKAGE__->pg_extensions(pg_trgm => { schema => 'k131_ext' });
  __PACKAGE__->register_class(Word => 'K131M::Result::Word');
}

my $dbh = LiveServer->control_dbh(login => [ @db ]);
sub namespace_exists {
  return scalar $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname = ?}, undef, $_[0]);
}
sub tables_in {
  return [ sort @{ $dbh->selectcol_arrayref(
    q{SELECT table_name FROM information_schema.tables WHERE table_schema = ?}, undef, $_[0]) } ];
}

# 1. Install into nothing: the namespace and the schema of the extension are made.
{
  my $schema = K131M::Schema->connect(@db, { schema => 'tenant_i', PrintWarn => 0 });
  ok !namespace_exists('tenant_i') && !namespace_exists('k131_ext'),
    'a database with neither the namespace nor the schema of the extension';
  ok eval { $schema->pg_deploy->install; 1 }, 'install runs through' or diag $@;
  ok namespace_exists('tenant_i') && namespace_exists('k131_ext'),
    '... it made the namespace and the schema of the extension';
  is_deeply tables_in('tenant_i'), ['words'], '... the table is in the namespace';
  $schema->storage->disconnect;
}

# 2. A namespace that is there already (made ahead): passed over, not made again.
{
  $dbh->do('CREATE SCHEMA tenant_j');
  my $schema = K131M::Schema->connect(@db, { schema => 'tenant_j', PrintWarn => 0 });
  ok eval { $schema->pg_deploy->install; 1 }, 'install over a namespace made ahead runs through' or diag $@;
  is_deeply tables_in('tenant_j'), ['words'], '... the table is in it';
  $schema->storage->disconnect;
}

# 3. The first diff: the namespace is created with the lookup, upgrade runs through.
{
  my $schema = K131M::Schema->connect(@db, { schema => 'tenant_k', PrintWarn => 0 });
  my $diff = eval { $schema->pg_deploy->diff };
  ok $diff, 'the first diff is built' or diag $@;
  like $diff ? $diff->as_sql : '', qr/nspname = 'tenant_k'.*?CREATE SCHEMA tenant_k;/s,
    '... and creates the namespace after a lookup in pg_namespace';
  ok eval { $schema->pg_deploy->upgrade; 1 }, 'upgrade from nothing runs through' or diag $@;
  ok namespace_exists('tenant_k'), '... the namespace is there';
  my $again = eval { $schema->pg_deploy->diff };
  ok $again && !$again->has_changes, 'a second diff is empty' or diag $again ? $again->as_sql : $@;
  $schema->storage->disconnect;
}

# 4. The same, namespace made ahead: the diff of a namespace that exists writes no creation of it.
{
  $dbh->do('CREATE SCHEMA tenant_l');
  my $schema = K131M::Schema->connect(@db, { schema => 'tenant_l', PrintWarn => 0 });
  my $diff = eval { $schema->pg_deploy->diff };
  ok $diff, 'diff over a namespace made ahead is built' or diag $@;
  unlike $diff ? $diff->as_sql : '', qr/CREATE SCHEMA tenant_l/,
    '... and does not create the namespace again';
  ok eval { $schema->pg_deploy->upgrade; 1 }, 'upgrade runs through' or diag $@;
  is_deeply tables_in('tenant_l'), ['words'], '... the table is in it';
  $schema->storage->disconnect;
}

done_testing;
