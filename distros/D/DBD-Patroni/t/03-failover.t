#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DBI;

# Skip if not in integration test environment
unless ( $ENV{PATRONI_URLS} && $ENV{TEST_FAILOVER} ) {
    plan skip_all =>
      'PATRONI_URLS and TEST_FAILOVER not set, skipping failover tests';
}

use_ok('DBD::Patroni');
use LWP::UserAgent;
use JSON;

my $patroni_urls = $ENV{PATRONI_URLS};
my $user         = $ENV{PGUSER}     || 'testuser';
my $pass         = $ENV{PGPASSWORD} || 'testpass';
my $dbname       = $ENV{PGDATABASE} || 'testdb';
my $sslmode      = $ENV{PGSSLMODE}  || 'disable';
my $dsn = "dbi:Patroni:dbname=$dbname;sslmode=$sslmode;patroni_url=$patroni_urls";

# Helper to get cluster info
sub get_cluster_info {
    my $ua = LWP::UserAgent->new( timeout => 5 );

    for my $url ( split /,/, $patroni_urls ) {
        my $resp = $ua->get($url);
        next unless $resp->is_success;

        my $data = eval { decode_json( $resp->decoded_content ) };
        next unless $data && $data->{members};

        my ($leader) = grep { $_->{role} eq 'leader' } @{ $data->{members} };
        my @replicas = grep { $_->{role} ne 'leader' } @{ $data->{members} };

        return {
            leader   => $leader,
            replicas => \@replicas,
            members  => $data->{members},
        };
    }
    return undef;
}

# Helper to trigger failover via Patroni API
sub trigger_failover {
    my ($new_leader) = @_;

    my $ua = LWP::UserAgent->new( timeout => 10 );

    # Find current leader's API endpoint
    my $info = get_cluster_info();
    return 0 unless $info && $info->{leader};

    my $leader_host  = $info->{leader}{host};
    my $failover_url = "http://${leader_host}:8008/failover";

    my $resp = $ua->post(
        $failover_url,
        'Content-Type' => 'application/json',
        Content        => encode_json( { candidate => $new_leader } ),
    );

    diag( "Failover response: " . $resp->status_line );
    diag( "Failover body: " . $resp->decoded_content ) if !$resp->is_success;

    return $resp->is_success;
}

# Wait for all replicas to be running
sub wait_for_replicas {
    my $max_attempts = shift || 60;

    for my $i ( 1 .. $max_attempts ) {
        my $info = get_cluster_info();
        next unless $info;

        # Count nodes that are running or streaming (replicas in sync)
        my @ready =
          grep { $_->{state} eq 'running' || $_->{state} eq 'streaming' }
          @{ $info->{members} };

        if ( @ready >= 3 ) {
            diag("All 3 nodes are ready");
            return 1;
        }

        # Show all states for debugging
        my $states =
          join( ", ", map { "$_->{name}:$_->{state}" } @{ $info->{members} } );
        diag("Attempt $i/$max_attempts: $states");
        sleep 5;
    }
    return 0;
}

# Wait for all nodes to be ready before starting tests
diag("Waiting for all cluster nodes to be ready...");
wait_for_replicas(60);    # 60 attempts x 5 seconds = 5 minutes max

# Test 1: Detect current leader
subtest 'Detect current leader' => sub {
    my $info = get_cluster_info();

    ok( $info,                       'Got cluster info' );
    ok( $info->{leader},             'Found leader' );
    ok( @{ $info->{replicas} } >= 1, 'Found at least one replica' );

    diag( "Current leader: " . $info->{leader}{host} );
    diag( "Replicas: "
          . join( ", ", map { $_->{host} } @{ $info->{replicas} } ) );
};

# Test 2: Connection survives leader change
subtest 'Connection survives leader change' => sub {
    my $dbh = DBI->connect( $dsn, $user, $pass );

    ok( $dbh, 'Initial connection' );

    # Insert a test row
    my $name = "failover_test_" . time();
    $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );

    # Get current leader
    my $info       = get_cluster_info();
    my $old_leader = $info->{leader}{host};
    diag("Old leader: $old_leader");

    # Choose a new leader from replicas
    my @replicas = @{ $info->{replicas} };
    skip "Need at least one replica for failover test", 3 unless @replicas;

    my $new_leader = $replicas[0]{name};
    diag("Triggering failover to: $new_leader");

    # Trigger failover
    my $failover_ok = trigger_failover($new_leader);
    ok( $failover_ok, 'Failover triggered' );

    # Wait for failover to complete
    diag("Waiting for failover to complete...");
    sleep 10;

    # Verify new leader
    $info = get_cluster_info();
    my $current_leader = $info->{leader}{host};
    diag("New leader: $current_leader");

    isnt( $current_leader, $old_leader, 'Leader has changed' );

    # Try to use the connection - it should auto-recover
    my $rv = eval {
        $dbh->do( "INSERT INTO logs (message) VALUES (?)",
            undef, "After failover" );
    };

    if ($@) {
        diag("First attempt failed (expected): $@");

        # The retry mechanism should kick in
        $rv = eval {
            $dbh->do( "INSERT INTO logs (message) VALUES (?)",
                undef, "After failover retry" );
        };
    }

    ok( $rv, 'Write operation works after failover' );

    # Read should also work
    my $sth =
      $dbh->prepare("SELECT message FROM logs ORDER BY id DESC LIMIT 1");
    $sth->execute;
    my ($msg) = $sth->fetchrow_array;

    like( $msg, qr/After failover/, 'Read operation works after failover' );

    $sth->finish;
    $dbh->disconnect;
};

# Test 3: New connection after failover
subtest 'New connection after failover' => sub {

    # Create a fresh connection after the failover
    my $dbh = eval { DBI->connect( $dsn, $user, $pass ) };

    ok( !$@,  'New connection after failover' ) or diag("Error: $@");
    ok( $dbh, 'Got database handle' );

    # Verify read/write works
    my $name = "post_failover_" . time();
    $dbh->do( "INSERT INTO users (name) VALUES (?)", undef, $name );

    sleep 1;

    my $sth = $dbh->prepare("SELECT name FROM users WHERE name = ?");
    $sth->execute($name);
    my ($result) = $sth->fetchrow_array;

    is( $result, $name, 'Read/Write works on new connection' );

    $sth->finish;
    $dbh->disconnect;
};

# Test 4: Cached connection survives failover
subtest 'Cached connection survives failover' => sub {

    # Wait for cluster to stabilize after previous tests
    diag("Waiting for cluster to stabilize before cached connection test...");
    wait_for_replicas(30);

    # Get a cached connection using DBI->connect_cached
    my $dbh1 = DBI->connect_cached( $dsn, $user, $pass, { RaiseError => 1 } );

    ok( $dbh1, 'Got cached connection' );

    # Verify it works
    my $name1 = "cached_before_" . time();
    $dbh1->do( "INSERT INTO users (name) VALUES (?)", undef, $name1 );
    diag("Inserted: $name1");

    # Get cluster state and trigger failover
    my $info       = get_cluster_info();
    my $old_leader = $info->{leader}{host};
    diag("Current leader before cached failover: $old_leader");

    my @replicas = @{ $info->{replicas} };
    skip "Need at least one replica for cached failover test", 4
      unless @replicas;

    # Find a replica that is ready (running or streaming)
    my ($ready_replica) =
      grep { $_->{state} eq 'running' || $_->{state} eq 'streaming' } @replicas;

    skip "No ready replica for failover", 4 unless $ready_replica;

    my $new_leader = $ready_replica->{name};
    diag("Triggering failover to: $new_leader");

    my $failover_ok = trigger_failover($new_leader);
    ok( $failover_ok, 'Failover triggered for cached test' );

    # Wait for failover
    diag("Waiting for failover to complete...");
    sleep 10;

    # Verify leader changed
    $info = get_cluster_info();
    my $current_leader = $info->{leader}{host};
    diag("New leader after cached failover: $current_leader");
    isnt( $current_leader, $old_leader, 'Leader has changed (cached test)' );

    # Get another cached connection - should return the same handle or reconnect
    my $dbh2 = DBI->connect_cached( $dsn, $user, $pass, { RaiseError => 1 } );

    ok( $dbh2, 'Got second cached connection' );

    # Try to use the cached connection - it should auto-recover
    my $name2 = "cached_after_" . time();
    my $rv    = eval {
        $dbh2->do( "INSERT INTO users (name) VALUES (?)", undef, $name2 );
    };

    if ($@) {
        diag("First cached attempt failed (expected): $@");

        # Retry - the reconnect should happen
        $rv = eval {
            $dbh2->do( "INSERT INTO users (name) VALUES (?)", undef, $name2 );
        };
    }

    ok( $rv, 'Write via cached connection works after failover' );

    # Verify data was written
    my $sth = $dbh2->prepare("SELECT name FROM users WHERE name = ?");
    $sth->execute($name2);
    my ($result) = $sth->fetchrow_array;
    $sth->finish;

    is( $result, $name2, 'Read via cached connection works after failover' );
};

# Test 5: Recovery from read-only error (simulates connecting to replica as leader)
subtest 'Recovery from read-only error' => sub {

    # Get cluster info to find a replica
    my $info = get_cluster_info();
    skip "Need replicas for read-only test", 3
      unless $info && @{ $info->{replicas} };

    my $replica = $info->{replicas}[0];
    diag("Testing read-only recovery using replica: $replica->{host}");

    # Create a DBD::Patroni connection normally
    my $dbh = DBI->connect( $dsn, $user, $pass );

    ok( $dbh, 'Got initial connection' );

    # Manually replace the leader connection with a replica connection
    # This simulates what happens when the leader becomes a replica after failover
    my $replica_dsn =
      "dbi:Pg:dbname=$dbname;host=$replica->{host};port=$replica->{port};sslmode=$sslmode";
    my $replica_dbh =
      DBI->connect( $replica_dsn, $user, $pass, { RaiseError => 1 } );
    skip "Cannot connect to replica directly", 2 unless $replica_dbh;

    # Save the real leader and replace with replica (access internal attribute)
    my $real_leader = $dbh->{patroni_leader_dbh};
    $dbh->{patroni_leader_dbh} = $replica_dbh;

    diag("Replaced leader connection with replica connection");

    # Try to write - this should fail with read-only error and trigger automatic recovery
    # The _with_retry mechanism should:
    # 1. Detect the read-only error
    # 2. Call _rediscover_cluster to reconnect to the real leader
    # 3. Retry the operation and succeed
    my $rv = eval {
        $dbh->do( "INSERT INTO logs (message) VALUES (?)",
            undef, "read-only test recovered" );
    };

    if ($@) {
        diag("Write attempt error: $@");
    }

    ok( $rv, 'Write succeeded after read-only recovery' );

    # Verify the data was written
    my $sth = $dbh->prepare(
        "SELECT message FROM logs WHERE message LIKE 'read-only test%' ORDER BY id DESC LIMIT 1"
    );
    $sth->execute;
    my ($msg) = $sth->fetchrow_array;
    $sth->finish;

    like( $msg, qr/read-only test/, 'Data was written after recovery' );

    # Cleanup
    $replica_dbh->disconnect if $replica_dbh;
    $dbh->disconnect;
};

# Test 6: Verify cluster state (informational - cluster may still be recovering)
subtest 'Verify cluster state after tests' => sub {
    my $info = get_cluster_info();

    ok( $info,           'Cluster is accessible' );
    ok( $info->{leader}, 'Cluster has a leader' );

    # Count running or streaming nodes
    my $ready = grep { $_->{state} eq 'running' || $_->{state} eq 'streaming' }
      @{ $info->{members} };

    diag("Final cluster state:");
    diag( "  Leader: " . $info->{leader}{host} );
    diag("  Ready members: $ready");
    for my $m ( @{ $info->{members} } ) {
        diag("    $m->{name}: $m->{state}");
    }

    # After failover, some nodes may still be recovering - just check we have a leader
    ok( 1, 'Cluster state logged' );
};

done_testing();
