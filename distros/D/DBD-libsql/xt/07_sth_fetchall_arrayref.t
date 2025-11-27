#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use DBI;
use LWP::UserAgent;
use JSON;

# Integration test for issue #19: $sth->fetchall_arrayref({}) returns empty array
# This test requires a running libsql/turso dev server
# It reproduces the exact scenario described in the issue

my $turso_bin;
BEGIN {
    eval { require Alien::Turso::CLI; };
    if ($@) {
        $turso_bin = `which turso 2>/dev/null`;
        chomp $turso_bin if $turso_bin;
        unless ($turso_bin && -x $turso_bin) {
            plan skip_all => 'turso CLI not found. Install Alien::Turso::CLI or system turso CLI';
        }
    } else {
        $turso_bin = Alien::Turso::CLI->bin_dir . '/turso';
    }
}

sub check_turso_dev_running {
    my $ua = LWP::UserAgent->new(timeout => 5);
    my $response = $ua->get('http://127.0.0.1:8080/health');
    return $response->is_success;
}

sub start_turso_dev_if_needed {
    return 1 if check_turso_dev_running();
    
    print "# Starting turso dev server...\n";
    my $pid = fork();
    if ($pid == 0) {
        exec($turso_bin, 'dev', '--port', '8080') or die "Failed to start turso dev: $!";
    } elsif (defined $pid) {
        sleep(3);
        for my $i (1..10) {
            if (check_turso_dev_running()) {
                print "# turso dev server started successfully\n";
                return 1;
            }
            sleep(1);
        }
        die "turso dev server failed to start";
    } else {
        die "Failed to fork: $!";
    }
}

unless (start_turso_dev_if_needed()) {
    plan skip_all => 'libsql server not available';
}

# Connect to libsql
my $dbh;
eval {
    $dbh = DBI->connect(
        "dbi:libsql:127.0.0.1?scheme=http&port=8080",
        "", "",
        { RaiseError => 1, AutoCommit => 1 }
    );
};

if ($@ || !$dbh) {
    plan skip_all => 'Could not connect to libsql server: ' . ($@ || 'unknown error');
}

plan tests => 15;

# Create test table and insert data
$dbh->do("DROP TABLE IF EXISTS test_posts");
$dbh->do(<<'SQL');
CREATE TABLE test_posts (
    id INTEGER PRIMARY KEY,
    name TEXT,
    message TEXT,
    timestamp TEXT
)
SQL

$dbh->do("INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)",
    undef,
    1,
    "User1",
    "Hello",
    "2024-01-01T00:00:00Z"
);

$dbh->do("INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)",
    undef,
    2,
    "User2",
    "World",
    "2024-01-02T00:00:00Z"
);

# Test 1: $dbh->selectall_arrayref with Slice => {} (database handle method)
{
    my $rows = $dbh->selectall_arrayref(
        "SELECT id, name, message FROM test_posts ORDER BY id",
        { Slice => {} }
    );
    
    ok(defined $rows, '$dbh->selectall_arrayref with Slice returns defined value');
    is(scalar(@$rows), 2, '$dbh->selectall_arrayref returns 2 rows');
    is(ref $rows->[0], 'HASH', 'Rows are hash references');
}

# Test 2: $sth->fetchall_arrayref with {} (statement handle method) - THE KEY BUG
{
    my $sth = $dbh->prepare("SELECT id, name, message FROM test_posts ORDER BY id");
    $sth->execute();
    
    my $rows = $sth->fetchall_arrayref({});
    
    ok(defined $rows, '$sth->fetchall_arrayref({}) returns defined value (not undef)');
    is(ref $rows, 'ARRAY', '$sth->fetchall_arrayref({}) returns array reference');
    is(scalar(@$rows), 2, '$sth->fetchall_arrayref({}) returns 2 rows (BUG: currently returns 0)');
    
    # Check that rows are hashes
    if (scalar(@$rows) > 0) {
        is(ref $rows->[0], 'HASH', 'Each row from fetchall_arrayref({}) is hash reference');
        is($rows->[0]->{id}, 1, 'First row id is 1');
        is($rows->[0]->{name}, 'User1', 'First row name is User1');
        is($rows->[0]->{message}, 'Hello', 'First row message is Hello');
    }
}

# Test 3: $sth->fetchrow_hashref in loop (workaround - this works)
{
    my $sth = $dbh->prepare("SELECT id, name, message FROM test_posts ORDER BY id");
    $sth->execute();
    
    my @rows;
    while (my $row = $sth->fetchrow_hashref()) {
        push @rows, $row;
    }
    
    is(scalar(@rows), 2, '$sth->fetchrow_hashref in loop returns 2 rows (workaround works)');
    is($rows[0]->{id}, 1, 'First row id via loop is 1');
    is($rows[1]->{id}, 2, 'Second row id via loop is 2');
}

# Test 4: $sth->fetchall_arrayref with default behavior
{
    my $sth = $dbh->prepare("SELECT id, name, message FROM test_posts ORDER BY id");
    $sth->execute();
    
    my $rows = $sth->fetchall_arrayref();
    
    ok(defined $rows, '$sth->fetchall_arrayref() with default returns defined value');
    is(scalar(@$rows), 2, '$sth->fetchall_arrayref() returns 2 rows');
}

# Cleanup
$dbh->do("DROP TABLE IF EXISTS test_posts");
$dbh->disconnect();

done_testing;
