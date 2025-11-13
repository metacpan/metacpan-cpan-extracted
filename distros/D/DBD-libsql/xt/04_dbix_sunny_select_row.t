#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use DBI;
use LWP::UserAgent;
use JSON;

# Integration test for issue #2: DBIx::Sunny select_row always returns undef
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

plan tests => 6;

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
    'Test User',
    'Test Message',
    '2024-01-01T00:00:00Z'
);

$dbh->do('INSERT INTO test_posts (id, name, message, timestamp) VALUES (?, ?, ?, ?)',
    undef,
    2,
    'Another User',
    'Another Message',
    '2024-01-02T00:00:00Z'
);

# Test 1: select_row should return a hashref, not undef
{
    my $row = $dbh->select_row(
        'SELECT id, name, message, timestamp FROM test_posts WHERE id = ?',
        1
    );
    
    ok(defined $row, 'select_row returns defined value (not undef)');
    is(ref $row, 'HASH', 'select_row returns a hash reference');
    is($row->{id}, 1, 'Column id is correct');
    is($row->{name}, 'Test User', 'Column name is correct');
    is($row->{message}, 'Test Message', 'Column message is correct');
    is($row->{timestamp}, '2024-01-01T00:00:00Z', 'Column timestamp is correct');
}

# Cleanup
$dbh->do('DROP TABLE IF EXISTS test_posts');
$dbh->disconnect();

done_testing;
