use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::DDL;

# OFFLINE test for karr k131 (a): the types and functions a class declares
# without naming a namespace go into the namespace of a connection with the
# connect key schema.
#
# CLAIM (a finding, nothing is built for it): the two declarations a tenant
# class has -- an enum column with extra => { list => [...] }, and raw SQL in
# pg_extra_ddl -- are written WITHOUT a schema on such a connection, so the
# search_path the script sets puts them into the namespace, as it does the
# tables. Written with one ("public.x") they would land elsewhere; so this
# test fails when a qualifier appears. The other declarations of types and
# functions (pg_enum, pg_type, pg_function) live on a PgSchema class, which
# is reached only through a pg_schema_class binding, and that is refused on
# such a connection (t/129-connection-schema.t).
#
# WHAT RUNS FOR REAL: install_ddl. THE SUBSTITUTION: no server.
# Live half: t/192-tenant-types-in-namespace-live.t.

my @LOGIN = ('dbi:Pg:dbname=k131_offline', 'u', 'p');

{
  package K131T::Result::Task;
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
  package K131T::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Task => 'K131T::Result::Task');
}

my $sql = DBIO::PostgreSQL::DDL->install_ddl(K131T::Schema->connect(@LOGIN, { schema => 'tenant_a' }));

like $sql, qr/^CREATE TYPE tasks_status_enum AS ENUM \('open', 'done'\);$/m,
  'the enum type of a column list is written without a schema';
like $sql, qr/^  status tasks_status_enum NOT NULL/m, '... and the column uses it so';
like $sql, qr/^CREATE FUNCTION task_count\(\)/m, 'a function in pg_extra_ddl is written as given, without a schema';
unlike $sql, qr/\b(?:public|tenant_a)\./, '... nothing in the script names a schema';

my @at = map { $sql =~ $_ ? $-[0] : undef } (
  qr/^SET search_path TO tenant_a/m, qr/^CREATE TYPE tasks_status_enum/m, qr/^CREATE FUNCTION/m,
);
ok !(grep { !defined } @at) && $at[0] < $at[1] && $at[0] < $at[2],
  '... and the search_path is set ahead of both, so the namespace is where they land'
  or diag $sql;

done_testing;
