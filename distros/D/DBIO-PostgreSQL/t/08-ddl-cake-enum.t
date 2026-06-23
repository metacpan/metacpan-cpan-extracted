use strict;
use warnings;

use Test::More;

use lib '../dbio/lib', 'lib';

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBIO::PostgreSQL::DDL;

# -----------------------------------------------------------------------
# Schema with a Cake-style enum column (no PgSchema enum declaration)
# -----------------------------------------------------------------------
{
  package CakeEnum::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  package CakeEnum::Schema::Result::Task;
  use DBIO::Moo;
  use DBIO::Cake '-retrieve_defaults';

  table 'task';

  col id     => serial;
  col status => enum(qw(pending running completed failed));
  col name   => text;

  primary_key 'id';
}

CakeEnum::Schema->register_class(Task => 'CakeEnum::Schema::Result::Task');

my $sql = DBIO::PostgreSQL::DDL->install_ddl('CakeEnum::Schema');

# The DDL must generate CREATE TYPE before CREATE TABLE
like($sql, qr/CREATE TYPE\b.*\bAS ENUM\b/si,
  'DDL contains CREATE TYPE ... AS ENUM');

like($sql, qr/CREATE TYPE\s+task_status_enum\s+AS ENUM\s*\('pending',\s*'running',\s*'completed',\s*'failed'\)/s,
  'enum type named {table}_{column}_enum with correct values');

# The CREATE TYPE must appear BEFORE the CREATE TABLE
my $type_pos  = index($sql, 'CREATE TYPE');
my $table_pos = index($sql, 'CREATE TABLE');
ok($type_pos >= 0, 'CREATE TYPE present');
ok($table_pos >= 0, 'CREATE TABLE present');
ok($type_pos < $table_pos, 'CREATE TYPE comes before CREATE TABLE');

# The column must use the generated type name, not bare 'enum'
like($sql, qr/status\s+task_status_enum\s+NOT NULL/s,
  'column uses generated enum type name');

unlike($sql, qr/status\s+enum\s+NOT NULL/s,
  'column does NOT use bare "enum" as type');

# -----------------------------------------------------------------------
# Schema with pg_schema (qualified enum type)
# -----------------------------------------------------------------------
{
  package CakeEnumNS::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('myapp');
}

{
  package CakeEnumNS::Schema::Result::Job;
  use DBIO::Moo;
  use DBIO::Cake;

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('myapp');

  table 'job';

  col id     => serial;
  col state  => enum(qw(queued active done));

  primary_key 'id';
}

CakeEnumNS::Schema->register_class(Job => 'CakeEnumNS::Schema::Result::Job');

my $ns_sql = DBIO::PostgreSQL::DDL->install_ddl('CakeEnumNS::Schema');

like($ns_sql, qr/CREATE TYPE\s+myapp\.job_state_enum\s+AS ENUM/s,
  'qualified enum type with pg_schema prefix');

like($ns_sql, qr/state\s+myapp\.job_state_enum/s,
  'column uses schema-qualified enum type name');

done_testing;
