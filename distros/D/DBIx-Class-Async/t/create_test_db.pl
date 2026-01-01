#!/usr/bin/env perl

# create_test_db.pl - Run this once to create the test database

use strict;
use warnings;
use DBI;
use File::Spec;

my $db_file = 'test.db';
unlink $db_file if -e $db_file;

my $dbh = DBI->connect("dbi:SQLite:$db_file", '', '', {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
});

$dbh->do('CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    active INTEGER DEFAULT 1 NOT NULL
)');

$dbh->do('CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT "pending" NOT NULL
)');

$dbh->do("INSERT INTO users (name, email, active) VALUES ('Test User', 'test\@example.com', 1)");
$dbh->do("INSERT INTO users (name, email, active) VALUES ('Another User', 'another\@example.com', 1)");
$dbh->do("INSERT INTO orders (user_id, amount, status) VALUES (1, 99.99, 'pending')");
$dbh->do("INSERT INTO orders (user_id, amount, status) VALUES (1, 149.99, 'completed')");

$dbh->disconnect;
print "Test database created at $db_file\n";
