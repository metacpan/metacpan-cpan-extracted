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

my $dbfile = 't/test_delete_integration.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef, undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

for my $i (1..5) {
    $schema->resultset('User')->create({
        name   => "User$i",
        email  => "user$i\@example.com",
        active => 1,
    });
}

subtest 'Row->delete() works' => sub {

    my $rs = $async_schema->resultset('User');
    my $users = $rs->all->get;

    my $user = $users->[0];
    ok($user->in_storage, 'User is in storage before delete');

    my $result = $user->delete->get;
    is($result, 1, 'delete() returns 1 on success');

    ok(!$user->in_storage, 'User not in storage after delete');
};

subtest 'Row->delete() on already deleted row' => sub {

    my $rs = $async_schema->resultset('User');
    my $users = $rs->all->get;

    my $user = $users->[0];
    $user->delete->get;  # First delete

    ok(!$user->in_storage, 'User not in storage');

    my $result = $user->delete->get;  # Try to delete again
    is($result, 0, 'delete() returns 0 when already deleted');
};

subtest 'delete_all() calls Row->delete()' => sub {

    # Reset data
    $schema->resultset('User')->delete;
    for my $i (1..3) {
        $schema->resultset('User')->create({
            name   => "TestUser$i",
            email  => "test$i\@example.com",
            active => 1,
        });
    }

    my $count_before = $schema->resultset('User')->count;
    is($count_before, 3, 'Have 3 users before delete_all');

    my $deleted = $async_schema->resultset('User')
        ->search({ name => { -like => 'TestUser%' } })
        ->delete_all->get;

    is($deleted, 3, 'delete_all() deleted 3 users');
};

subtest 'delete_all() vs delete() behavior' => sub {

    # Reset and create identical datasets
    $schema->resultset('User')->delete;

    for my $i (1..5) {
        $schema->resultset('User')->create({
            name   => "User$i",
            email  => "user$i\@example.com",
            active => ($i <= 3) ? 1 : 0,
        });
    }

    # Test delete_all on first 3
    my $deleted_all = $async_schema->resultset('User')
        ->search({ active => 1 })
        ->delete_all->get;

    is($deleted_all, 3, 'delete_all deleted 3 active users');
    is($schema->resultset('User')->count, 2, '2 users remain');

    # Reset data
    $schema->resultset('User')->delete;
    for my $i (1..5) {
        $schema->resultset('User')->create({
            name   => "User$i",
            email  => "user$i\@example.com",
            active => ($i <= 3) ? 1 : 0,
        });
    }

    # Test delete on first 3
    my $deleted_bulk = $async_schema->resultset('User')
        ->search({ active => 1 })
        ->delete->get;

    is($deleted_bulk, 3, 'delete deleted 3 active users');
    is($schema->resultset('User')->count, 2, '2 users remain');
};

END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
