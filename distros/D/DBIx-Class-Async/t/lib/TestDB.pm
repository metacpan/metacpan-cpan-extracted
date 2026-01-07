package TestDB;

use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT = qw(
    setup_test_db
    teardown_test_db
    get_test_schema_class
    TEST_USERS
    TEST_POSTS
);

use DBI;
use File::Temp 'tempdir';
use Path::Tiny;

our $TEST_DB_DIR;
our $TEST_DB_FILE;

our @TEST_USERS = (
    { name => 'Alice',   email => 'alice@example.com',   active => 1 },
    { name => 'Bob',     email => 'bob@example.com',     active => 1 },
    { name => 'Charlie', email => 'charlie@example.com', active => 0 },
    { name => 'Diana',   email => 'diana@example.com',   active => 1 },
);

our @TEST_ORDERS = (
    { user_id => 1, amount => 100.99,  status => 'active' },
    { user_id => 2, amount => 111.01,  status => 'active' },
    { user_id => 1, amount => 99.20,   status => 'pending' },
);

sub setup_test_db {
    $TEST_DB_DIR = tempdir(CLEANUP => 1);
    $TEST_DB_FILE = "$TEST_DB_DIR/test.db";

    my $dbh = DBI->connect("dbi:SQLite:dbname=$TEST_DB_FILE", undef, undef, {
        RaiseError => 0,
        PrintError => 0,
        sqlite_unicode => 1,
    });

    # Create tables
    $dbh->do(q{
        CREATE TABLE users (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  VARCHAR(100) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            active INTEGER DEFAULT 1
        )
    });

    $dbh->do(q{
        CREATE TABLE orders (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            amount  DECIMAL(10,2) NOT NULL,
            status  VARCHAR(255) NOT NULL DEFAULT 'pending'
        )
    });

    # Insert test data
    my $user_sth = $dbh->prepare(
        "INSERT INTO users (name, email, active) VALUES (?, ?, ?)"
    );

    my $order_sth = $dbh->prepare(
        "INSERT INTO orders (user_id, amount, status) VALUES (?, ?, ?)"
    );

    foreach my $user (@TEST_USERS) {
        $user_sth->execute(@{$user}{qw/name email active/});
    }

    foreach my $order (@TEST_ORDERS) {
        $order_sth->execute(@{$order}{qw/user_id amount status/});
    }

    $dbh->disconnect;

    return $TEST_DB_FILE;
}

sub teardown_test_db {
    if ($TEST_DB_FILE && -e $TEST_DB_FILE) {
        unlink $TEST_DB_FILE;
    }
}

sub get_test_schema_class {
    # Return a pre-defined test schema class
    return 'TestSchema';
}
1;
