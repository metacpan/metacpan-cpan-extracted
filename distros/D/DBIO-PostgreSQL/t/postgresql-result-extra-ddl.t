#!perl
use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Result;

{
    package TestResult::ExtraDDL;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('test_table');
}

# 1. Single string
TestResult::ExtraDDL->pg_extra_ddl('ALTER TABLE x ADD COLUMN y int');
is_deeply(TestResult::ExtraDDL->pg_extra_ddl,
   ['ALTER TABLE x ADD COLUMN y int'],
   'single string appended');

# 2. Multiple calls append
TestResult::ExtraDDL->pg_extra_ddl('CREATE INDEX idx ON x(y)');
is(scalar @{ TestResult::ExtraDDL->pg_extra_ddl }, 2, 'second call appends');

# 3. Arrayref form
{
    package TestResult::ExtraDDL2;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('test_table2');
}
TestResult::ExtraDDL2->pg_extra_ddl(['ALTER TABLE a DROP col', 'CREATE INDEX idx2 ON a(b)']);
is(scalar @{ TestResult::ExtraDDL2->pg_extra_ddl }, 2, 'arrayref flattens');

# 4. DDL emission strips trailing semicolons
{
    package MockSchema::ExtraDDL;
    sub sources { 'TestResult::ExtraDDL' }
    sub pg_extensions { }
    sub pg_schemas { }
    sub pg_settings { }
    sub pg_search_path { }
    sub pg_schema_class { undef }
    sub source {
        my ($self, $name) = @_;
        return MockSchema::ExtraDDL::Source->new($name);
    }
    package MockSchema::ExtraDDL::Source;
    sub new { bless { name => $_[1] }, $_[0] }
    sub name { $_[0]->{name} }
    sub result_class { 'TestResult::ExtraDDL' }
    sub columns { 'y' }
    sub column_info { { data_type => 'integer' } }
    sub primary_columns { }
}
my $ddl_out = DBIO::PostgreSQL::DDL->install_ddl('MockSchema::ExtraDDL');
like($ddl_out, qr'ALTER TABLE x ADD COLUMN y int',
     'pg_extra_ddl emitted in DDL output');
like($ddl_out, qr'CREATE INDEX idx ON x',
     'multiple pg_extra_ddl entries emitted');

done_testing;