#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";

print "1..9\n";

use DBI;
use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async;
use DBIx::Class::Async::Schema;
use DBIx::Class::Async::ResultSet;
use DBIx::Class::Async::Row;

my $dbh = DBI->connect("dbi:SQLite:dbname=debug.db", "", "", {
    RaiseError => 1,
    PrintError => 0,
});

$dbh->do("DROP TABLE IF EXISTS users");
$dbh->do("DROP TABLE IF EXISTS orders");

$dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(50), email VARCHAR(100), active INTEGER DEFAULT 1)");
$dbh->do("CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, amount DECIMAL(10,2), status VARCHAR(20) DEFAULT 'pending')");
$dbh->disconnect;

print "ok 1 - Database created\n";

my $loop  = IO::Async::Loop->new;
my $async = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ['dbi:SQLite:dbname=debug.db'],
    workers      => 1,
    loop         => $loop,
);

print "ok 2 - Async instance created\n";

my $user_hash = $async->create('User', {
    name  => 'Debug User',
    email => 'debug@example.com',
})->get;

print "ok 3 - Direct create worked, got hashref with keys: " . join(', ', keys %$user_hash) . "\n";

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=debug.db",
    undef,
    undef,
    {},
    {
        workers      => 1,
        schema_class => 'TestSchema',
        loop         => $loop
    }
);

print "ok 4 - Schema wrapper connected\n";

my $rs = $schema->resultset('User');
print "ok 5 - Got resultset: " . ref($rs) . "\n";

if ($rs->isa('DBIx::Class::Async::ResultSet')) {
    print "ok 6 - ResultSet is correct type\n";
} else {
    print "not ok 6 - ResultSet is wrong type: " . ref($rs) . "\n";
}

my $create_future = $rs->create({
    name  => 'Wrapper User',
    email => 'wrapper@example.com',
});

print "ok 7 - Create future created\n";

eval {
    my $user_obj = $create_future->get;
    print "ok 8 - Got user object: " . ref($user_obj) . "\n";

    if ($user_obj->isa('DBIx::Class::Async::Row')) {
        print "ok 9 - User is Row object\n";

        # Try to access name
        eval {
            my $name = $user_obj->name;
            print "# Got name: $name\n";
        } or do {
            print "# Failed to get name: $@\n";
        };

        # Try get_column
        eval {
            my $name = $user_obj->get_column('name');
            print "# get_column('name'): $name\n";
        } or do {
            print "# get_column failed: $@\n";
        };

        # Dump the object
        print "# Object dump:\n";
        foreach my $key (keys %$user_obj) {
            print "#   $key: " . (ref $user_obj->{$key} ? ref $user_obj->{$key} : $user_obj->{$key}) . "\n";
        }
    } else {
        print "not ok 9 - User is not Row object: " . ref($user_obj) . "\n";
    }

    1;
} or do {
    my $error = $@;
    print "not ok 8 - Failed to get user: $error\n";
    print "not ok 9 - Skipped\n";
};

$async->disconnect;
unlink 'debug.db';
