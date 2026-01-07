#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Future;
use lib 't/lib';

use TestDB;
use TestSchema;
use DBIx::Class::Async;

my $db_file = TestDB::setup_test_db();
my $async   = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:dbname=$db_file", "", ""],
    workers      => 1,
);

my $user_data = {
    name   => 'Eve',
    email  => 'eve@example.com',
    active => 1,
};

my $create_future = $async->create('User', $user_data);

ok($create_future->isa('Future'), 'create() returns Future');

my $user = $create_future->get;

ok($user, 'Future resolved to a row hashref');

is($user->{name}, 'Eve', 'name correct');
is($user->{email}, 'eve@example.com', 'email correct');
ok($user->{id}, 'id auto-generated');

my $found_future = $async->find('User', $user->{id});
my $found = $found_future->get;

ok($found && $found->{email} eq 'eve@example.com', 'found user with correct email');

TestDB::teardown_test_db();

done_testing();
