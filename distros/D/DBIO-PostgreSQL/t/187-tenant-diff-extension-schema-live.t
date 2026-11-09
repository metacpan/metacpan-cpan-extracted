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

# LIVE test for karr k131 (c): the first diff of a connection with the connect
# key schema, in a database that has neither the namespace nor the schema of
# the declared extension.
#
# CLAIM: upgrade from nothing runs through. The deploy sees the namespace
# alone, so the diff cannot see the schema the extension is declared in; its
# CREATE EXTENSION ... WITH SCHEMA is behind a CREATE SCHEMA IF NOT EXISTS and
# the server finds the schema. Before, it failed with 'schema "k131_ext" does
# not exist'. Offline half: t/186-tenant-diff-extension-schema.t.

my @db = PrivatePgDatabase->create('t187');

{
  package K131L::Result::Word;
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
  package K131L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('k131_ext');
  __PACKAGE__->pg_extensions(pg_trgm => { schema => 'k131_ext' });
  __PACKAGE__->register_class(Word => 'K131L::Result::Word');
}

my $dbh = LiveServer->control_dbh(login => [ @db ]);
sub namespace_exists {
  return scalar $dbh->selectrow_array(
    q{SELECT count(*) FROM pg_catalog.pg_namespace WHERE nspname = ?}, undef, $_[0]);
}
sub extension_schema {
  return scalar $dbh->selectrow_array(
    q{SELECT n.nspname FROM pg_catalog.pg_extension e
        JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
       WHERE e.extname = ?}, undef, $_[0]);
}

ok !namespace_exists('k131_ext') && !namespace_exists('tenant_f'),
  'a database with neither the namespace nor the schema of the extension';

my $schema = K131L::Schema->connect(@db, { schema => 'tenant_f', PrintWarn => 0 });
my $diff = eval { $schema->pg_deploy->diff };
ok $diff, 'the first diff is built' or diag $@;
like $diff ? $diff->as_sql : '', qr/nspname = 'k131_ext'.*?CREATE SCHEMA k131_ext;/s,
  '... and creates the schema of the extension';

ok eval { $schema->pg_deploy->upgrade; 1 }, 'upgrade from nothing runs through' or diag $@;
is extension_schema('pg_trgm'), 'k131_ext', '... the extension is in its schema';
ok namespace_exists('tenant_f'), '... the namespace is there';

my $again = eval { $schema->pg_deploy->diff };
ok $again && !$again->has_changes, 'a second diff is empty' or diag $again ? $again->as_sql : $@;

$schema->storage->disconnect;
$dbh->disconnect;

done_testing;
