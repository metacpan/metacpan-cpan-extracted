#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DBI;
use lib '../lib';

# Skip tests if environment variables are not set
my $turso_url = $ENV{TURSO_DATABASE_URL};
my $turso_token = $ENV{TURSO_DATABASE_TOKEN};

if (!$turso_url || !$turso_token) {
    plan skip_all => 
        "Turso Cloud live tests require environment variables to be set:\n" .
        "  TURSO_DATABASE_URL - The libsql database URL (e.g., libsql://your-db.turso.io)\n" .
        "  TURSO_DATABASE_TOKEN - Your authentication token from Turso dashboard\n" .
        "\n" .
        "To run these tests, export the variables and run:\n" .
        "  export TURSO_DATABASE_URL='libsql://...'\n" .
        "  export TURSO_DATABASE_TOKEN='...'\n" .
        "  prove -Ilib xt/03_turso_live.t\n";
}

# Extract hostname from Turso URL
# Expected format: libsql://database-name-author.region.turso.io
my $hostname;
if ($turso_url =~ m|^libsql://([^/]+)|) {
    $hostname = $1;
} else {
    plan skip_all => 
        "Invalid TURSO_DATABASE_URL format: '$turso_url'\n" .
        "Expected format: libsql://database-name-author.region.turso.io\n" .
        "Get the correct URL from your Turso dashboard at https://app.turso.io\n";
}

plan tests => 8;

# Test 1: Connection with Turso credentials (using DBI standard password parameter)
my $dsn = "dbi:libsql:$hostname";
my $dbh = DBI->connect($dsn, '', $turso_token, {
    RaiseError => 1,
    AutoCommit => 1,
});

ok($dbh, 'Successfully connected to Turso database');
isa_ok($dbh, 'DBI::db', 'Database handle');

# Test 2: Create test table
my $table_name = 'dbd_libsql_test_' . time();  # Unique table name
eval {
    $dbh->do("DROP TABLE IF EXISTS $table_name");
    $dbh->do("CREATE TABLE $table_name (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
};
ok(!$@, "Created test table '$table_name'") or diag("Error: $@");

# Test 3: Insert test data
my @test_data = (
    [1, 'Alice Johnson', 'alice@example.com'],
    [2, 'Bob Smith', 'bob@example.com'],
    [3, 'Carol Brown', 'carol@example.com'],
);

my $insert_count = 0;
for my $row (@test_data) {
    my $result = eval {
        $dbh->do("INSERT INTO $table_name (id, name, email) VALUES (?, ?, ?)", 
                undef, @$row);
    };
    if (!$@ && $result) {
        $insert_count++;
    }
}
is($insert_count, 3, 'Inserted all test records');

# Test 4: Query and verify data
my $count_result = eval {
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM $table_name");
    $sth->execute();
    my ($count) = $sth->fetchrow_array();
    $sth->finish();
    return $count;
};
if ($@) {
    diag("COUNT query failed: $@");
    fail('Count query execution');
} else {
    is($count_result, 3, 'Correct number of records in table');
}

# Test 5: Test SELECT with WHERE clause
my ($name, $email) = eval {
    my $sth = $dbh->prepare("SELECT name, email FROM $table_name WHERE id = ?");
    $sth->execute(2);
    my @row = $sth->fetchrow_array();
    $sth->finish();
    return @row;
};
if ($@) {
    diag("SELECT query failed: $@");
    fail('SELECT with WHERE clause - name');
    fail('SELECT with WHERE clause - email');
} else {
    is($name, 'Bob Smith', 'Retrieved correct name');
    is($email, 'bob@example.com', 'Retrieved correct email');
}

# Test 6: Update and verify
my $updated_rows = eval {
    $dbh->do("UPDATE $table_name SET email = ? WHERE id = ?", 
             undef, 'bob.smith@company.com', 2);
};
if ($@) {
    diag("UPDATE query failed: $@");
    fail('Update record');
} else {
    is($updated_rows, 1, 'Updated one record');
}

# Cleanup: Drop test table
eval {
    $dbh->do("DROP TABLE IF EXISTS $table_name");
};

$dbh->disconnect();

done_testing();