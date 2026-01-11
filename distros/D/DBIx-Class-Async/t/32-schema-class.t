#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use lib 'lib';

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use TestSchema;
use DBIx::Class::Async::Schema;

my $dbfile = 't/test_class_method.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

subtest 'class() - returns correct class name' => sub {

    my $user_class = $async_schema->class('User');
    is($user_class, 'TestSchema::Result::User',
        'Returns correct class name for User');

    my $order_class = $async_schema->class('Order');
    is($order_class, 'TestSchema::Result::Order',
        'Returns correct class name for Order');
};

subtest 'class() - returned class is valid' => sub {

    my $user_class = $async_schema->class('User');

    ok($user_class, 'Returns a defined value');
    ok(!ref($user_class), 'Returns a string, not a reference');

    my $loaded = eval "require $user_class; 1";
    ok($loaded, 'Returned class can be loaded');
    ok(!$@, 'No errors loading the class');
};

subtest 'class() - returned class has expected methods' => sub {

    my $user_class = $async_schema->class('User');

    can_ok($user_class, 'table');
    can_ok($user_class, 'columns');
    can_ok($user_class, 'primary_columns');
    can_ok($user_class, 'column_info');
    can_ok($user_class, 'has_column');
    can_ok($user_class, 'new');
};

subtest 'class() - can call class methods' => sub {

    my $user_class = $async_schema->class('User');
    my $table      = $user_class->table;

    is($table, 'users', 'Can get table name');

    my @columns = $user_class->columns;
    ok(@columns > 0, 'Can get columns list');
    ok((grep { $_ eq 'id' } @columns), 'Column list includes id');
    ok((grep { $_ eq 'name' } @columns), 'Column list includes name');

    my @pk = $user_class->primary_columns;
    is_deeply(\@pk, ['id'], 'Can get primary key columns');
};

subtest 'class() - column introspection' => sub {

    my $user_class = $async_schema->class('User');

    ok($user_class->has_column('name'), 'has_column works for existing column');
    ok(!$user_class->has_column('nonexistent'), 'has_column returns false for non-existent');

    my $name_info = $user_class->column_info('name');
    ok($name_info, 'Can get column_info');
    isa_ok($name_info, 'HASH', 'column_info returns hashref');
    is($name_info->{data_type}, 'varchar', 'Column has correct data_type');
    is($name_info->{size}, 100, 'Column has correct size');
};

subtest 'class() - multiple sources' => sub {

    my $user_class  = $async_schema->class('User');
    my $order_class = $async_schema->class('Order');

    isnt($user_class, $order_class, 'Different sources return different classes');

    is($user_class->table, 'users', 'User class has correct table');
    is($order_class->table, 'orders', 'Order class has correct table');
};

subtest 'class() - consistency with regular schema' => sub {

    my $regular_user_class = $schema->class('User');
    my $async_user_class   = $async_schema->class('User');

    is($async_user_class, $regular_user_class,
        'Async and regular schemas return same class name');

    is($async_user_class->table, $regular_user_class->table,
        'Classes from both schemas have same table');
};

subtest 'class() - error: non-existent source' => sub {

    eval {
        $async_schema->class('NonExistentSource');
    };

    ok($@, 'Dies when source does not exist');
    like($@, qr/No such source/i, 'Error message mentions missing source');
};

subtest 'class() - error: missing argument' => sub {

    eval {
        $async_schema->class();
    };

    ok($@, 'Dies when called without argument');
    like($@, qr/required/i, 'Error message mentions required argument');
};

subtest 'class() - error: undefined argument' => sub {

    eval {
        $async_schema->class(undef);
    };

    ok($@, 'Dies when argument is undef');
    like($@, qr/required/i, 'Error message mentions required argument');
};

subtest 'class() - works with empty database' => sub {

    my $user_class = $async_schema->class('User');

    ok($user_class, 'Returns class even with empty database');
    is($user_class, 'TestSchema::Result::User',
        'Returns correct class regardless of data');
};

subtest 'class() - case sensitivity' => sub {

    my $user_class = $async_schema->class('User');

    ok($user_class, 'Correct case works');

    eval {
        $async_schema->class('user');  # lowercase
    };
    ok($@, 'Wrong case causes error');

    eval {
        $async_schema->class('USER');  # uppercase
    };
    ok($@, 'All caps causes error');
};

subtest 'class() - can instantiate objects from class' => sub {

    my $user_class = $async_schema->class('User');
    my $user       = $user_class->new({
        name   => 'TestUser',
        email  => 'test@example.com',
        active => 1,
    });

    isa_ok($user, $user_class, 'new() creates object of correct class');
    isa_ok($user, 'DBIx::Class::Core', 'Object inherits from DBIx::Class::Core');

    is($user->name, 'TestUser', 'Object has correct attribute');
    ok(!$user->in_storage, 'Object is not in storage yet');
};

subtest 'class() - use for validation' => sub {

    my $user_class    = $async_schema->class('User');
    my @valid_columns = $user_class->columns;
    my %valid         = map { $_ => 1 } @valid_columns;

    ok($valid{name}, 'name is a valid column');
    ok($valid{email}, 'email is a valid column');

    ok(!$valid{invalid_column}, 'invalid_column is not valid');
};

subtest 'class() - get default values' => sub {

    my $user_class  = $async_schema->class('User');
    my $active_info = $user_class->column_info('active');

    is($active_info->{default_value}, 1,
        'Can get default value from column_info');

    my $email_info = $user_class->column_info('email');
    ok(!defined $email_info->{default_value} || $email_info->{is_nullable},
        'Nullable columns may not have defaults');
};

subtest 'class() - nullable vs required' => sub {

    my $user_class = $async_schema->class('User');
    my $name_info  = $user_class->column_info('name');

    ok(!$name_info->{is_nullable}, 'name is NOT NULL');

    my $email_info = $user_class->column_info('email');
    ok($email_info->{is_nullable}, 'email is nullable');

    my $id_info = $user_class->column_info('id');
    ok(!$id_info->{is_nullable}, 'id is NOT NULL');
};

subtest 'class() - auto increment detection' => sub {

    my $user_class = $async_schema->class('User');
    my $id_info    = $user_class->column_info('id');

    ok($id_info->{is_auto_increment}, 'id is auto increment');
};

subtest 'class() - called multiple times returns same result' => sub {

    my $class1 = $async_schema->class('User');
    my $class2 = $async_schema->class('User');
    my $class3 = $async_schema->class('User');

    is($class1, $class2, 'First and second call return same class');
    is($class2, $class3, 'Second and third call return same class');
    is($class1, $class3, 'First and third call return same class');
};

subtest 'class() - works for all registered sources' => sub {

    my @sources = $async_schema->sources;
    my $success = 1;
    foreach my $source_name (@sources) {
        eval {
            my $class = $async_schema->class($source_name);
            $success = 0 unless $class;
        };
        $success = 0 if $@;
    }

    ok($success, 'Can get class for all registered sources');
};

END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
