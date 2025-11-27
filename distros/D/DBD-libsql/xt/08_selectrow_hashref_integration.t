#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use DBI;
use LWP::UserAgent;
use JSON;

# Integration test for issue #15: selectrow_hashref returns non-standard hash structure
# This test requires a running libsql/turso dev server
# It reproduces the exact scenario from the issue report

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
$dbh->do("DROP TABLE IF EXISTS posts");
$dbh->do(<<'SQL');
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    name TEXT,
    message TEXT,
    timestamp TEXT
)
SQL

$dbh->do("INSERT INTO posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)",
    undef,
    1,
    'テストユーザー',
    'テストメッセージ',
    '2025-11-12 03:44:18'
);

# Reproduction code from issue #15
# Issue: selectrow_hashref returns non-standard hash structure
# Expected: { 'id' => '1', 'name' => 'テストユーザー', 'message' => 'テストメッセージ', 'timestamp' => '2025-11-12 03:44:18' }
# Actual (buggy): { 'value' => 'テストメッセージ', 'name' => 'テストユーザー', 'id' => '1' } (missing timestamp, message becomes value)

my $row = $dbh->selectrow_hashref(
    'SELECT id, name, message, timestamp FROM posts WHERE id = 1'
);

# Expected behavior tests
ok(defined $row, 'selectrow_hashref returns defined value (not undef)');
is(ref $row, 'HASH', 'selectrow_hashref returns hash reference');

# Test that all expected columns are present
ok(exists $row->{id}, 'Hash has id column');
ok(exists $row->{name}, 'Hash has name column');
ok(exists $row->{message}, 'Hash has message column');
ok(exists $row->{timestamp}, 'Hash has timestamp column');

# Test that column values are correct
is($row->{id}, '1', 'Column id has correct value: 1');
is($row->{name}, 'テストユーザー', 'Column name has correct value');
is($row->{message}, 'テストメッセージ', 'Column message has correct value (NOT "value")');
is($row->{timestamp}, '2025-11-12 03:44:18', 'Column timestamp has correct value');

# Test that buggy 'value' column does NOT exist
ok(!exists $row->{value}, 'Hash should NOT have "value" column (bug: message was mapped to value)');

# Verify hash structure has exactly the expected columns
my @expected_cols = sort qw(id name message timestamp);
my @actual_cols = sort keys %$row;
is_deeply(\@actual_cols, \@expected_cols, 'Hash has exactly the expected columns');

# Test with different column order in SELECT statement
my $row2 = $dbh->selectrow_hashref(
    'SELECT timestamp, message, name, id FROM posts WHERE id = 1'
);

ok(defined $row2, 'selectrow_hashref with different column order returns defined value');
is($row2->{id}, '1', 'Column id correct with different column order');
is($row2->{message}, 'テストメッセージ', 'Column message correct with different column order');

# Cleanup
$dbh->do("DROP TABLE IF EXISTS posts");
$dbh->disconnect();

done_testing;
