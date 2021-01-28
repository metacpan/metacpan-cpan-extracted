use Mojo::Base -strict;

use Test::More;
use CellBIS::SQL::Abstract::Test;

use Mojo::File 'curfile';
use lib curfile->sibling('lib')->to_string;

plan skip_all => 'set TEST_ONLINE_pg to enable this test'
  unless $ENV{TEST_ONLINE_pg};

my $dsn = $ENV{TEST_ONLINE_pg};
my ($test, $db, $backend, $id);

# Initialization for SQLite
$test = CellBIS::SQL::Abstract::Test->new(table => 'users', via => 'pg',
  dsn => $dsn);

$backend = $test->backend;
$db      = $backend->db;

note 'connection test';
ok $db->ping, 'connected';

note 'for table users';
is $test->check_table->{result} => undef, 'no table';
is $test->create_table->{code}  => 200,   'success create table';
is $test->empty_table->{code}   => 200,   'empty table';
is $test->drop_table->{code}    => 200,   'drop table';

note 'for table roles';
$test->table('roles');
is $test->check_table->{result} => undef, 'no table';
is $test->create_table->{code}  => 200,   'success create table';
is $test->empty_table->{code}   => 200,   'empty table';
is $test->drop_table->{code}    => 200,   'drop table';

note 'for table relations';
is $test->check_table->{result} => undef, 'no table roles';
is $test->create_table->{code}  => 200,   'success create table roles';
$test->table('users');
is $test->check_table->{result}        => undef, 'no table users';
is $test->create_table_with_fk->{code} => 200,   'success create table users';
is $test->drop_table->{code}           => 200,   'drop table';
$test->table('roles');
is $test->drop_table->{code} => 200, 'drop table';

done_testing();
