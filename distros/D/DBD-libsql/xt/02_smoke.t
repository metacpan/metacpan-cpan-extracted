#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DBI;

# Quick smoke test for DBD::libsql with turso dev
# This test assumes turso dev is already running

BEGIN {
    # Check if turso dev is running
    my $ua;
    eval {
        require LWP::UserAgent;
        $ua = LWP::UserAgent->new(timeout => 2);
        my $response = $ua->get('http://127.0.0.1:8080/health');
        die "Server not responding" unless $response->is_success;
    };
    
    if ($@) {
        plan skip_all => 'turso dev server not running. Start with: turso dev';
    }
}

plan tests => 5;

# Test 1: Basic connection
my $dbh = DBI->connect("dbi:libsql:127.0.0.1?schema=http&port=8080", "", "");
ok($dbh, 'Connected to turso dev server');

# Test 2: Simple CREATE TABLE
ok($dbh->do("CREATE TABLE IF NOT EXISTS smoke_test (id INTEGER PRIMARY KEY, message TEXT)"), 
   'Created table');

# Test 3: INSERT data
ok($dbh->do("INSERT OR REPLACE INTO smoke_test (id, message) VALUES (1, 'Hello from DBD::libsql!')"), 
   'Inserted data');

# Test 4: SELECT data
my $sth = $dbh->prepare("SELECT message FROM smoke_test WHERE id = ?");
ok($sth->execute(1), 'Executed SELECT');

my $row = $sth->fetchrow_arrayref();
is($row->[0], 'Hello from DBD::libsql!', 'Retrieved correct data');

# Cleanup
$sth->finish();
$dbh->disconnect();

done_testing;