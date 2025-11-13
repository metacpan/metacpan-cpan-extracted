#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use DBI;
use LWP::UserAgent;
use JSON;

# Integration test for issue #3: DBIx::Sunny select_all always returns empty array
# This test requires a running libsql/turso dev server

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

# Test with DBIx::Sunny
my $dbh;
eval {
    require DBIx::Sunny;
    $dbh = DBIx::Sunny->connect('dbi:libsql:localhost');
};

if ($@ || !$dbh) {
    plan skip_all => 'Could not connect to libsql server with DBIx::Sunny: ' . ($@ || 'unknown error');
}

# Check if select_all method exists
unless ($dbh->can('select_all')) {
    plan skip_all => 'DBIx::Sunny does not have select_all method';
}

plan tests => 8;

# Create test table and insert data
$dbh->do('DROP TABLE IF EXISTS test_posts');
$dbh->do(<<'SQL');
CREATE TABLE test_posts (
    id INTEGER PRIMARY KEY,
    name TEXT,
    message TEXT,
    timestamp TEXT
)
SQL

$dbh->do('INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)',
    undef,
    1,
    'User 1',
    'Message 1',
    '2024-01-01T00:00:00Z'
);

$dbh->do('INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)',
    undef,
    2,
    'User 2',
    'Message 2',
    '2024-01-02T00:00:00Z'
);

$dbh->do('INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)',
    undef,
    3,
    'User 3',
    'Message 3',
    '2024-01-03T00:00:00Z'
);

# Test 1: select_all should return an array of hashes, not empty array
{
    my $rows = $dbh->select_all(
        'SELECT id, name, message, timestamp FROM test_posts ORDER BY id ASC'
    );
    
    ok(defined $rows, 'select_all returns defined value');
    is(ref $rows, 'ARRAY', 'select_all returns an array reference');
    is(scalar @$rows, 3, 'select_all returns 3 rows');
    
    # Check first row
    my $first = $rows->[0];
    is(ref $first, 'HASH', 'Each row is a hash reference');
    is($first->{id}, 1, 'First row id is 1');
    is($first->{name}, 'User 1', 'First row name is correct');
    
    # Check that we got multiple rows
    my $third = $rows->[2];
    is($third->{id}, 3, 'Third row id is 3');
    is($third->{name}, 'User 3', 'Third row name is correct');
}

# Cleanup
$dbh->do('DROP TABLE IF EXISTS test_posts');
$dbh->disconnect();

done_testing;
