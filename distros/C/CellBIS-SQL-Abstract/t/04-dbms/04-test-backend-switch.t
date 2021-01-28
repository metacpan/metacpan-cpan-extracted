use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CellBIS::SQL::Abstract::Test;

plan skip_all =>
  'set TEST_ONLINE_mariadb and TEST_ONLINE_pg to enable this test'
  unless $ENV{TEST_ONLINE_mariadb} && $ENV{TEST_ONLINE_pg};

BEGIN {
  $ENV{PLACK_ENV}    = undef;
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojo::File 'curfile';
use lib curfile->sibling('lib')->to_string;

my ($test, $db, $backend);

# Initialization for SQLite
$test = CellBIS::SQL::Abstract::Test->new(table => 'users');
unless (-d $test->dir) { mkdir $test->dir }

$backend = $test->backend;
$db      = $backend->db;

note 'sqlite - connection test';
ok $db->ping, 'connected';

note 'sqlite - for table users';
is $test->check_table->{result} => undef, 'no table';
is $test->create_table->{code}  => 200,   'success create table';
is $test->empty_table->{code}   => 200,   'empty table';
is $test->drop_table->{code}    => 200,   'drop table';

note 'sqlite - for table roles';
$test->table('roles');
is $test->check_table->{result} => undef, 'no table';
is $test->create_table->{code}  => 200,   'success create table';
is $test->empty_table->{code}   => 200,   'empty table';
is $test->drop_table->{code}    => 200,   'drop table';

note 'sqlite - for relation table';
is $test->check_table->{result} => undef, 'no table roles';
is $test->create_table->{code}  => 200,   'success create table roles';
$test->table('users');
is $test->check_table->{result}        => undef, 'no table users';
is $test->create_table_with_fk->{code} => 200,   'success create table users';

$test->dir->remove_tree;

# Switch to MariaDB
$test->dsn($ENV{TEST_ONLINE_mariadb});
$test->change_dbms('mariadb');
$backend = $test->backend;
$db      = $backend->db;

note 'mariadb - connection test';
ok $db->ping, 'connected';

note 'mariadb - for table users';
$test->table('users');
is $test->check_table->{result} => undef, 'mariadb - no table';
is $test->create_table->{code}  => 200,   'mariadb - success create table';
is $test->empty_table->{code}   => 200,   'mariadb - empty table';
is $test->drop_table->{code}    => 200,   'mariadb - drop table';

note 'mariadb - for table roles';
$test->table('roles');
is $test->check_table->{result} => undef, 'mariadb - no table';
is $test->create_table->{code}  => 200,   'mariadb - success create table';
is $test->empty_table->{code}   => 200,   'mariadb - empty table';
is $test->drop_table->{code}    => 200,   'mariadb - drop table';

note 'mariadb - for relation table';
is $test->check_table->{result} => undef, 'mariadb - no table roles';
is $test->create_table->{code} => 200, 'mariadb - success create table roles';
$test->table('users');
is $test->check_table->{result} => undef, 'mariadb - no table users';
is $test->create_table_with_fk->{code} => 200,
  'mariadb - success create table users';
is $test->drop_table->{code} => 200, 'mariadb - drop table';
$test->table('roles');
is $test->drop_table->{code} => 200, 'mariadb - drop table';

# switch to PostgreSQL
$test->dsn($ENV{TEST_ONLINE_pg});
$test->change_dbms('pg');
$backend = $test->backend;
$db      = $backend->db;

note 'pg - connection test';
ok $db->ping, 'connected';

note 'pg - for table users';
$test->table('users');
is $test->check_table->{result} => undef, 'pg - no table';
is $test->create_table->{code}  => 200,   'pg - success create table';
is $test->empty_table->{code}   => 200,   'pg - empty table';
is $test->drop_table->{code}    => 200,   'pg - drop table';

note 'pg - for table roles';
$test->table('roles');
is $test->check_table->{result} => undef, 'pg - no table';
is $test->create_table->{code}  => 200,   'pg - success create table';
is $test->empty_table->{code}   => 200,   'pg - empty table';
is $test->drop_table->{code}    => 200,   'pg - drop table';

note 'pg - for relation table';
is $test->check_table->{result} => undef, 'pg - no table roles';
is $test->create_table->{code}  => 200,   'pg - success create table roles';
$test->table('users');
is $test->check_table->{result} => undef, 'pg - no table users';
is $test->create_table_with_fk->{code} => 200,
  'pg - success create table users';
is $test->drop_table->{code} => 200, 'pg - drop table';
$test->table('roles');
is $test->drop_table->{code} => 200, 'pg - drop table';

# Switch back to SQLite
$test->change_dbms('sqlite');
unless (-d $test->dir) { mkdir $test->dir }
$backend = $test->backend;
$db      = $backend->db;

note 'back to sqlite - connection test';
ok $db->ping, 'connected';

note 'back to sqlite - for table users';
$test->table('users');
is $test->check_table->{result} => undef, 'back to sqlite - no table';
is $test->create_table->{code}  => 200, 'back to sqlite - success create table';
is $test->empty_table->{code}   => 200, 'back to sqlite - empty table';
is $test->drop_table->{code}    => 200, 'back to sqlite - drop table';

$test->dir->remove_tree;

done_testing();
