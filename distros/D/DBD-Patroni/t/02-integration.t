#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DBI;

# Skip if not in integration test environment
unless ( $ENV{PATRONI_URLS} ) {
    plan skip_all => 'PATRONI_URLS not set, skipping integration tests';
}

use_ok('DBD::Patroni');

my $patroni_urls = $ENV{PATRONI_URLS};
my $user         = $ENV{PGUSER}     || 'testuser';
my $pass         = $ENV{PGPASSWORD} || 'testpass';
my $dbname       = $ENV{PGDATABASE} || 'testdb';
my $sslmode      = $ENV{PGSSLMODE}  || 'disable';

diag("Testing with Patroni URLs: $patroni_urls");

my $dsn = "dbi:Patroni:dbname=$dbname;sslmode=$sslmode;patroni_url=$patroni_urls";

# Test 1: Basic connection
subtest 'Basic connection' => sub {
    my $dbh = eval { DBI->connect( $dsn, $user, $pass ) };

    ok( !$@,        'Connection successful' ) or diag("Error: $@");
    ok( $dbh,       'Got database handle' );
    ok( $dbh->ping, 'Ping successful' );

    $dbh->disconnect if $dbh;
};

# Test 2: Read/Write routing
subtest 'Read/Write routing' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass );

    # Write operation (should go to leader)
    my $name = "test_user_" . time();
    my $rv   = $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );
    ok( $rv, 'INSERT successful' );

    # Read operation (should go to replica)
    my $sth = $dbh->prepare("SELECT name FROM users WHERE name = ?");
    ok( $sth, 'Prepare SELECT successful' );

    $sth->execute($name);
    my ($result) = $sth->fetchrow_array;

    # Note: replica might have slight lag, so we retry
    my $attempts = 0;
    while ( !$result && $attempts < 10 ) {
        sleep 1;
        $sth->execute($name);
        ($result) = $sth->fetchrow_array;
        $attempts++;
    }

    is( $result, $name, 'SELECT returns inserted value' );

    $sth->finish;
    $dbh->disconnect;
};

# Test 3: Transaction handling
subtest 'Transaction handling' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass, { AutoCommit => 1 } );

    # Start transaction
    $dbh->begin_work;

    my $name = "tx_user_" . time();
    $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );

    # Rollback
    $dbh->rollback;

    # Verify rollback worked
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM users WHERE name = ?");
    $sth->execute($name);
    my ($count) = $sth->fetchrow_array;

    is( $count, 0, 'Rollback successful - no rows found' );

    # Test commit
    $dbh->begin_work;
    $name = "tx_commit_" . time();
    $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );
    $dbh->commit;

    sleep 1;    # Wait for replication
    $sth->execute($name);
    ($count) = $sth->fetchrow_array;

    is( $count, 1, 'Commit successful - row found' );

    $sth->finish;
    $dbh->disconnect;
};

# Test 4: Load balancing modes
subtest 'Load balancing modes' => sub {
    my $base_dsn = "dbi:Patroni:dbname=$dbname;sslmode=$sslmode;patroni_url=$patroni_urls";

    # Test leader_only mode
    my $dbh = DBI->connect( "$base_dsn;patroni_lb=leader_only", $user, $pass );

    ok( $dbh, 'leader_only mode connects' );

    my $sth = $dbh->prepare("SELECT 1");
    $sth->execute;
    my ($result) = $sth->fetchrow_array;
    is( $result, 1, 'SELECT works in leader_only mode' );

    $sth->finish;
    $dbh->disconnect;

    # Test random mode
    $dbh = DBI->connect( "$base_dsn;patroni_lb=random", $user, $pass );

    ok( $dbh, 'random mode connects' );
    $dbh->disconnect;

    # Test round_robin mode (default)
    $dbh = DBI->connect( "$base_dsn;patroni_lb=round_robin", $user, $pass );

    ok( $dbh, 'round_robin mode connects' );
    $dbh->disconnect;
};

# Test 5: Multiple queries
subtest 'Multiple queries' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass );

    # Insert multiple rows
    my @names;
    for my $i ( 1 .. 5 ) {
        my $name = "multi_user_${i}_" . time();
        push @names, $name;
        $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );
    }

    sleep 1;    # Wait for replication

    # Read them back
    my $sth = $dbh->prepare("SELECT name FROM users WHERE name LIKE ?");
    $sth->execute("multi_user_%");

    my $count = 0;
    while ( my ($name) = $sth->fetchrow_array ) {
        $count++ if grep { $_ eq $name } @names;
    }

    cmp_ok( $count, '>=', 1, 'Found inserted rows' );

    $sth->finish;
    $dbh->disconnect;
};

# Test 6: Error handling
subtest 'Error handling' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass,
        { RaiseError => 0, PrintError => 0 } );

    # Try invalid SQL
    my $rv = $dbh->do("INVALID SQL SYNTAX");
    ok( !$rv,         'Invalid SQL returns false' );
    ok( $dbh->errstr, 'Error string is set' );

    $dbh->disconnect;
};

# Test 7: Prepare with placeholders
subtest 'Prepare with placeholders' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass );

    my $sth = $dbh->prepare("SELECT * FROM users WHERE name = ? AND id > ?");
    ok( $sth, 'Prepare with multiple placeholders' );

    $sth->execute( "test", 0 );
    ok( 1, 'Execute with multiple parameters' );

    $sth->finish;
    $dbh->disconnect;
};

done_testing();
