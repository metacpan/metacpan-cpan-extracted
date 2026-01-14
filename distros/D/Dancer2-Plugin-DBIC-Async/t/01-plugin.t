#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);

use DBI;
use IO::Async::Loop;
use lib 't/lib';

my $dir     = tempdir(CLEANUP => 1);
my $db_file = catfile($dir, 'test.db');

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

$dbh->do(q{
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )
});

$dbh->do(q{ INSERT INTO users (name) VALUES ('Alice') });
$dbh->do(q{ INSERT INTO users (name) VALUES ('Bob') });
$dbh->do(q{ INSERT INTO users (name) VALUES ('Charlie') });

$dbh->disconnect;

require_ok('Test::Schema');
require_ok('Test::Schema::Result::User');
require_ok('DBIx::Class::Async');

my $loop  = IO::Async::Loop->new;
my $async = DBIx::Class::Async->new(
    schema_class => 'Test::Schema',
    connect_info => [
        "dbi:SQLite:dbname=$db_file",
        '',
        '',
        { sqlite_unicode => 1 },
    ],
    workers => 2,
    loop    => $loop,
);

subtest 'Count' => sub {

    my $count = $async->count('User')->get;
    is($count, 3, 'Count returns 3 users');
};

subtest 'Find' => sub {

    my $user = $async->find('User', 1)->get;
    ok($user, 'Find returns a user');
    is($user->{name}, 'Alice', 'Found user is Alice');
};

subtest 'Search' => sub {

    my $users = $async->search('User', { name => 'Bob' })->get;
    is($users->[0]{name}, 'Bob', 'Search finds Bob');
};

subtest 'Create' => sub {

    my $result = $async->create('User', { name => 'David' })->get;
    ok($result, 'Create succeeded');

    my $count = $async->count('User')->get;
    is($count, 4, 'Count increased to 4');
};

subtest 'Update' => sub {

    my $result = $async->update('User', 1, { name => 'Alice Updated' })->get;
    ok($result, 'Update succeeded');

    my $user = $async->find('User', 1)->get;
    is($user->{name}, 'Alice Updated', 'User was updated');
};

subtest 'Delete' => sub {

    my $result = $async->delete('User', 2)->get;
    ok($result, 'Delete succeeded');

    my $count = $async->count('User')->get;
    is($count, 3, 'Count decreased to 3');
};

$async->disconnect if $async->can('disconnect');

done_testing();
