#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use DBI;
use LWP::UserAgent;
use JSON;

# Integration test for issue #16: selectall_arrayref { Slice => {} } option not working
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

$dbh->do("INSERT INTO posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)",
    undef,
    2,
    '新しいユーザー',
    '新しいメッセージ',
    '2025-11-12 03:48:40'
);

# Reproduction code from issue #16
# Issue: selectall_arrayref { Slice => {} } option is ignored
# Expected: Returns array of hash references when { Slice => {} } is provided
# Actual (buggy): Returns array of array references (option ignored)

my $rows = $dbh->selectall_arrayref(
    'SELECT id, name, message, timestamp FROM posts ORDER BY id DESC',
    { Slice => {} }
);

# Expected behavior tests
ok(defined $rows, 'selectall_arrayref with Slice returns defined value');
is(ref $rows, 'ARRAY', 'selectall_arrayref with Slice returns array reference');
is(scalar(@$rows), 2, 'selectall_arrayref returns 2 rows');

# Test that rows are hash references, not array references
is(ref $rows->[0], 'HASH', 'First row with Slice => {} is hash reference (not array)');
is(ref $rows->[1], 'HASH', 'Second row with Slice => {} is hash reference (not array)');

# Test values in first row
is($rows->[0]->{id}, '2', 'First row id is 2 (DESC order)');
is($rows->[0]->{name}, '新しいユーザー', 'First row name is correct');
is($rows->[0]->{message}, '新しいメッセージ', 'First row message is correct');
is($rows->[0]->{timestamp}, '2025-11-12 03:48:40', 'First row timestamp is correct');

# Test values in second row
is($rows->[1]->{id}, '1', 'Second row id is 1');
is($rows->[1]->{name}, 'テストユーザー', 'Second row name is correct');
is($rows->[1]->{message}, 'テストメッセージ', 'Second row message is correct');
is($rows->[1]->{timestamp}, '2025-11-12 03:44:18', 'Second row timestamp is correct');

# Test that without Slice option, default behavior works
my $default_rows = $dbh->selectall_arrayref(
    'SELECT id, name FROM posts ORDER BY id'
);

is(ref $default_rows->[0], 'ARRAY', 'Without Slice option, returns array references (default behavior)');
is($default_rows->[0]->[0], '1', 'First element of first row is id=1');

# Cleanup
$dbh->do("DROP TABLE IF EXISTS posts");
$dbh->disconnect();

done_testing;
