#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";

print "1..5\n";

# Test 1: Load DBIx::Class::Async directly
eval {
    require DBIx::Class::Async;
    require TestSchema;

    # Create database
    use DBI;
    my $dbh = DBI->connect("dbi:SQLite:dbname=test.db", "", "", {
        RaiseError => 1,
        PrintError => 0,
    });

    $dbh->do("DROP TABLE IF EXISTS users");
    $dbh->do("DROP TABLE IF EXISTS orders");

    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(50), email VARCHAR(100), active INTEGER DEFAULT 1)");
    $dbh->do("CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, amount DECIMAL(10,2), status VARCHAR(20) DEFAULT 'pending')");
    $dbh->disconnect;

    print "ok 1 - Setup complete\n";

    # Create async instance
    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $async = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => ['dbi:SQLite:dbname=test.db'],
        workers => 1,
        loop => $loop,
    );

    print "ok 2 - Async instance created\n";

    # Create user
    my $future = $async->create('User', {
        name => 'Direct Test',
        email => 'test@example.com',
    });

    # Get result
    my $user = $future->get;

    if ($user && ref $user eq 'HASH' && $user->{name} eq 'Direct Test') {
        print "ok 3 - User created: $user->{id}\n";
    } else {
        print "not ok 3 - User creation failed\n";
        exit 1;
    }

    # Find user
    my $find_future = $async->find('User', $user->{id});
    my $found = $find_future->get;

    if ($found && $found->{id} == $user->{id}) {
        print "ok 4 - User found\n";
    } else {
        print "not ok 4 - User not found\n";
    }

    $async->disconnect;
    print "ok 5 - Cleanup done\n";

    # Cleanup
    unlink 'test.db';

    1;
} or do {
    my $error = $@;
    print "not ok 1 - $error\n";
    exit 1;
};
