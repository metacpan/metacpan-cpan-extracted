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

# LIVE test for karr k131 (a): the enum type of a column list and a function
# in pg_extra_ddl land in the namespace of a connection with the connect key
# schema -- one set per tenant, none in public. Offline half:
# t/191-tenant-types-in-namespace.t.

my @db = PrivatePgDatabase->create('t192');

{
  package K131U::Result::Task;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('tasks');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    status => { data_type => 'enum', extra => { list => [qw( open done )] } },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_extra_ddl(
    'CREATE FUNCTION task_count() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM tasks $$',
  );
}
{
  package K131U::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Task => 'K131U::Result::Task');
}

my $dbh = LiveServer->control_dbh(login => [ @db ]);
sub types_in {
  return [ sort @{ $dbh->selectcol_arrayref(
    q{SELECT t.typname FROM pg_catalog.pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
       WHERE n.nspname = ? AND t.typtype = 'e'}, undef, $_[0]) } ];
}
sub functions_in {
  return [ sort @{ $dbh->selectcol_arrayref(
    q{SELECT p.proname FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = ?}, undef, $_[0]) } ];
}

my @schemas = map { K131U::Schema->connect(@db, { schema => $_, PrintWarn => 0 }) } qw( tenant_a tenant_b );
for my $schema (@schemas) {
  my $ns = $schema->storage->connection_schema;
  ok eval { $schema->pg_deploy->install; 1 }, "$ns: install runs through" or diag $@;
  is_deeply types_in($ns), ['tasks_status_enum'], "$ns: the enum type is in the namespace";
  is_deeply functions_in($ns), ['task_count'], "$ns: the function is in the namespace";
}
is_deeply types_in('public'), [], 'nothing of it is in public';
is_deeply functions_in('public'), [], '... neither the function';

for my $schema (@schemas) {
  my $diff = eval { $schema->pg_deploy->diff };
  ok $diff && !$diff->has_changes, $schema->storage->connection_schema . ': a diff after the install is empty'
    or diag $diff ? $diff->as_sql : $@;
  $schema->storage->disconnect;
}

done_testing;
