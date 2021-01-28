use Mojo::Base -strict;

use Test::More;
use CellBIS::SQL::Abstract::Test;

use Mojo::File 'curfile';
use lib curfile->sibling('lib')->to_string;

my ($test, $db, $backend);

# Initialization for SQLite
$test = CellBIS::SQL::Abstract::Test->new(table => 'users');
unless (-d $test->dir) { mkdir $test->dir }

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

note 'for relation table';
is $test->check_table->{result} => undef, 'no table roles';
is $test->create_table->{code}  => 200,   'success create table roles';
$test->table('users');
is $test->check_table->{result}        => undef, 'no table users';
is $test->create_table_with_fk->{code} => 200,   'success create table users';

$test->dir->remove_tree;

done_testing();
