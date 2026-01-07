#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";

use DBI;
use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async;

use File::Temp;
my ($fh, $db_file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
    RaiseError => 1,
    PrintError => 0,
});

$dbh->do("
    CREATE TABLE users (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        name   VARCHAR(50) NOT NULL,
        email  VARCHAR(100),
        active INTEGER NOT NULL DEFAULT 1
    )
");

$dbh->do("
    CREATE TABLE orders (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount  DECIMAL(10,2) NOT NULL,
        status  VARCHAR(20) NOT NULL DEFAULT 'pending'
    )
");

$dbh->disconnect;

my $loop = IO::Async::Loop->new;

# Test 1: Direct DBIx::Class::Async connection
subtest 'Direct async connection' => sub {

    my $async_db;
    lives_ok {
        $async_db = DBIx::Class::Async->new(
            schema_class => 'TestSchema',
            connect_info => [
                "dbi:SQLite:dbname=$db_file",
                undef,
                undef,
                {}
            ],
            workers => 2,
            loop => $loop,
        );
    } 'DBIx::Class::Async connects successfully';

    isa_ok($async_db, 'DBIx::Class::Async');

    my $search_future = $async_db->search('User', {});
    isa_ok($search_future, 'Future');

    my $users = $search_future->get;
    isa_ok($users, 'ARRAY');
    is(scalar @$users, 0, 'No users initially');

    $async_db->disconnect;
};

# Test 2: Direct create and find
subtest 'Direct create and find' => sub {

    my $async_db = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => [
            "dbi:SQLite:dbname=$db_file",
            undef,
            undef,
            {}
        ],
        workers => 2,
        loop => $loop,
    );

    # Create user
    my $create_future = $async_db->create('User', {
        name => 'Direct Test',
        email => 'direct@example.com',
        active => 1,
    });

    my $user = $create_future->get;
    isa_ok($user, 'HASH', 'create returns hashref');
    is($user->{name}, 'Direct Test');
    is($user->{email}, 'direct@example.com');

    # Find user
    my $find_future = $async_db->find('User', $user->{id});
    my $found = $find_future->get;
    isa_ok($found, 'HASH', 'find returns hashref');
    is($found->{name}, 'Direct Test');

    # Update user
    my $update_future = $async_db->update('User', $user->{id}, {
        name => 'Updated Direct',
        active => 0,
    });
    my $updated = $update_future->get;
    is($updated->{name}, 'Updated Direct');
    is($updated->{active}, 0);

    # Count users
    my $count_future = $async_db->count('User', {});
    my $count = $count_future->get;
    cmp_ok($count, '>=', 1, 'Counts users');

    # Search users
    my $search_future = $async_db->search('User', { active => 0 });
    my $inactive_users = $search_future->get;
    is(scalar @$inactive_users, 1, 'Found inactive user');

    $async_db->disconnect;
};

done_testing();
