#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DBI;
use Data::Dumper;
use lib 'lib';

# Reproduction test based on Issue #1 comment #3578378444
# Bug Report: $sth->fetchall_arrayref({}) returns empty array
#
# This test reproduces the exact issue from kfly8's bug report:
# https://github.com/ytnobody/p5-DBD-libsql/issues/1#issuecomment-3578378444

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
    my $ua;
    eval { require LWP::UserAgent; };
    if ($@) {
        return 0;  # If LWP::UserAgent not available, assume not running
    }
    $ua = LWP::UserAgent->new(timeout => 5);
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

plan tests => 8;

# Setup test data
$dbh->do("DROP TABLE IF EXISTS test_posts");
$dbh->do("CREATE TABLE test_posts (id INTEGER PRIMARY KEY, name TEXT, message TEXT)");
$dbh->do("INSERT INTO test_posts (name, message) VALUES (?, ?)", undef, "User1", "Hello");
$dbh->do("INSERT INTO test_posts (name, message) VALUES (?, ?)", undef, "User2", "World");

# Test 1: $dbh->selectall_arrayref with Slice => {}
{
    my $rows1 = $dbh->selectall_arrayref(
        "SELECT id, name, message FROM test_posts ORDER BY id",
        { Slice => {} }
    );
    
    ok(defined $rows1, 'Test 1: $dbh->selectall_arrayref with Slice => {} returns defined value');
    is(scalar(@$rows1), 2, 'Test 1: Returns 2 rows');
    is(ref $rows1->[0], 'HASH', 'Test 1: Each row is a hash reference');
}

# Test 2: $sth->fetchall_arrayref({}) - The main bug that was fixed
{
    my $sth = $dbh->prepare("SELECT id, name, message FROM test_posts ORDER BY id");
    $sth->execute();
    my $rows2 = $sth->fetchall_arrayref({});
    
    ok(defined $rows2, 'Test 2: $sth->fetchall_arrayref({}) returns defined value');
    is(scalar(@$rows2), 2, 'Test 2: Returns 2 rows (BUG FIX: was returning 0 rows)');
    is(ref $rows2->[0], 'HASH', 'Test 2: Each row is a hash reference');
    is($rows2->[0]->{id}, '1', 'Test 2: First row id is correct');
    is($rows2->[0]->{name}, 'User1', 'Test 2: First row name is correct');
}

# Cleanup
$dbh->do("DROP TABLE IF EXISTS test_posts");
$dbh->disconnect();

done_testing;
