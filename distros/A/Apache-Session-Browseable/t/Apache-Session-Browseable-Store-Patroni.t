#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => "Optional modules (DBD::Pg, DBI) not installed"
  unless eval {
    require DBI;
    require DBD::Pg;
  };

plan tests => 34;

my $package = 'Apache::Session::Browseable::Store::Patroni';

use_ok($package);

my $store = $package->new;
isa_ok( $store, $package );

# Test _buildDataSource function
{
    no warnings 'once';

    # Basic case: append host/port
    is(
        Apache::Session::Browseable::Store::Patroni::_buildDataSource(
            'dbi:Pg:dbname=sessions', { host => '10.0.0.1', port => 5432 }
        ),
        'dbi:Pg:dbname=sessions;host=10.0.0.1;port=5432',
        '_buildDataSource: basic append'
    );

    # Replace existing host/port (semicolon separated)
    is(
        Apache::Session::Browseable::Store::Patroni::_buildDataSource(
            'dbi:Pg:dbname=sessions;host=old.host;port=1234',
            { host => '10.0.0.2', port => 5433 }
        ),
        'dbi:Pg:dbname=sessions;host=10.0.0.2;port=5433',
        '_buildDataSource: replace existing host/port'
    );

    # Handle trailing colon in DSN
    is(
        Apache::Session::Browseable::Store::Patroni::_buildDataSource(
            'dbi:Pg:', { host => '10.0.0.3', port => 5434 }
        ),
        'dbi:Pg:host=10.0.0.3;port=5434',
        '_buildDataSource: trailing colon'
    );

    # Complex DSN with other params
    is(
        Apache::Session::Browseable::Store::Patroni::_buildDataSource(
            'dbi:Pg:dbname=mydb;host=127.0.0.1;port=5432;sslmode=require',
            { host => '192.168.1.1', port => 5435 }
        ),
        'dbi:Pg:dbname=mydb;sslmode=require;host=192.168.1.1;port=5435',
        '_buildDataSource: complex DSN with other params'
    );
}

# Test cache structure (multi-source support)
{
    no warnings 'once';

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

    my $ds1 = 'dbi:Pg:dbname=db1';
    my $ds2 = 'dbi:Pg:dbname=db2';

    # Simulate caching for first datasource
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds1} = {
        leader => {
            host => '10.0.0.1',
            port => 5432,
            time => time()
        }
    };

    # Simulate caching for second datasource
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds2} = {
        leader => {
            host => '10.0.0.2',
            port => 5433,
            time => time()
        }
    };

    # Verify they are independent
    is(
        $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds1}
          ->{leader}->{host},
        '10.0.0.1', 'Multi-source: first datasource has correct host'
    );
    is(
        $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds2}
          ->{leader}->{host},
        '10.0.0.2', 'Multi-source: second datasource has correct host'
    );

    # Verify ports are independent
    is(
        $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds1}
          ->{leader}->{port},
        5432, 'Multi-source: first datasource has correct port'
    );
    is(
        $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds2}
          ->{leader}->{port},
        5433, 'Multi-source: second datasource has correct port'
    );

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test _useCachedLeader
{
    no warnings 'once';

    my $ds    = 'dbi:Pg:dbname=testdb';
    my $store = $package->new;
    $store->{_originalDataSource} = $ds;

    # No cache - should return 0
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
    my $args = { DataSource => $ds, PatroniCacheTTL => 60 };

    # Capture STDERR
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->_useCachedLeader( $args, $ds, "Test reason" );
        is( $result, 0, '_useCachedLeader: returns 0 when no cache' );
    }

    # With valid cache
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds} = {
        leader => {
            host => '10.0.0.5',
            port => 5432,
            time => time() - 10    # 10 seconds ago
        }
    };

    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->_useCachedLeader( $args, $ds, "Test reason" );
        is( $result, 1, '_useCachedLeader: returns 1 when cache valid' );
    }
    like( $args->{DataSource}, qr/host=10\.0\.0\.5/,
        '_useCachedLeader: updates DataSource with cached host' );
    like( $args->{DataSource}, qr/port=5432/,
        '_useCachedLeader: updates DataSource with cached port' );

    # With expired cache
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds} = {
        leader => {
            host => '10.0.0.6',
            port => 5433,
            time => time() - 120    # 2 minutes ago, expired
        }
    };
    $args = { DataSource => $ds, PatroniCacheTTL => 60 };

    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->_useCachedLeader( $args, $ds, "Test reason" );
        is( $result, 0, '_useCachedLeader: returns 0 when cache expired' );
    }

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test circuit breaker logic in checkMaster (without actual HTTP calls)
{
    no warnings 'once';

    my $ds    = 'dbi:Pg:dbname=circuitdb';
    my $store = $package->new;
    $store->{_originalDataSource} = $ds;

    # Set up circuit breaker as triggered
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds} = {
        lastFailure => time() - 10,    # Failed 10 seconds ago
        leader      => {
            host => '10.0.0.7',
            port => 5432,
            time => time() - 5         # Cached 5 seconds ago
        }
    };

    my $args = {
        DataSource                 => $ds,
        PatroniUrl                 => 'http://fake.patroni:8008/cluster',
        PatroniCircuitBreakerDelay => 30,
        PatroniCacheTTL            => 60,
    };

    # Circuit breaker should be active (failed 10s ago, delay is 30s)
    # It should use cached leader instead of calling API
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->checkMaster($args);
        is( $result, 1, 'Circuit breaker: uses cached leader when active' );
    }
    like(
        $stderr,
        qr/Circuit breaker active/,
        'Circuit breaker: prints appropriate message'
    );
    like( $args->{DataSource}, qr/host=10\.0\.0\.7/,
        'Circuit breaker: uses cached host' );

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test that circuit breaker expires
{
    no warnings 'once';

    my $ds    = 'dbi:Pg:dbname=expiredcb';
    my $store = $package->new;
    $store->{_originalDataSource} = $ds;

    # Circuit breaker triggered long ago (should be expired)
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds} = {
        lastFailure => time() - 60,    # Failed 60 seconds ago
        leader      => {
            host => '10.0.0.8',
            port => 5432,
            time => time() - 50        # Still valid cache
        }
    };

    my $args = {
        DataSource                 => $ds,
        PatroniUrl                 => 'http://nonexistent.host:8008/cluster',
        PatroniCircuitBreakerDelay => 30,    # Expired (60 > 30)
        PatroniCacheTTL            => 120,
    };

    # Circuit breaker should NOT be active (failed 60s ago, delay is 30s)
    # It will try to call API (which will fail) then use cache
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;

        # This will try HTTP (fail) then fallback to cache
        my $result = $store->checkMaster($args);
        is( $result, 1,
            'Circuit breaker expired: uses cache after API failure' );
    }
    like(
        $stderr,
        qr/Patroni API unavailable/,
        'Circuit breaker expired: API was tried'
    );

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test default values
{
    my $store = $package->new;
    my $ds    = 'dbi:Pg:dbname=defaults';
    $store->{_originalDataSource} = $ds;

    # Test with minimal args
    my $args = {
        DataSource => $ds,
        PatroniUrl => 'http://fake:8008/cluster',
    };

    # Without cache, checkMaster will try HTTP and fail
    # This tests that defaults are applied correctly
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;

        # Store the time before calling checkMaster
        my $before = time();
        my $result = $store->checkMaster($args);

        # Verify failure was recorded with correct circuit breaker
        my $cache =
          $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds};
        ok( $cache->{lastFailure} >= $before,
            'Default circuit breaker delay: failure recorded' );
    }

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test custom TTL values
{
    no warnings 'once';

    my $ds = 'dbi:Pg:dbname=customttl';

    # Set up cache with known age
    $Apache::Session::Browseable::Store::Patroni::patroniCache{$ds} = {
        leader => {
            host => '10.0.0.9',
            port => 5432,
            time => time() - 45    # 45 seconds ago
        }
    };

    my $store = $package->new;
    $store->{_originalDataSource} = $ds;

    # With 30s TTL, cache should be expired
    my $args1  = { DataSource => $ds, PatroniCacheTTL => 30 };
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->_useCachedLeader( $args1, $ds, "Test" );
        is( $result, 0, 'Custom TTL 30s: cache expired at 45s' );
    }

    # With 60s TTL, cache should be valid
    my $args2 = { DataSource => $ds, PatroniCacheTTL => 60 };
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        my $result = $store->_useCachedLeader( $args2, $ds, "Test" );
        is( $result, 1, 'Custom TTL 60s: cache valid at 45s' );
    }

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}

# Test module can be loaded
use_ok('Apache::Session::Browseable::Patroni');

# Test JSON parsing and leader validation with mocked HTTP using LWP::Protocol::PSGI
SKIP: {
    skip 'LWP::Protocol::PSGI and JSON not available', 10
      unless eval { require LWP::Protocol::PSGI; require JSON; 1 };

    my $package = 'Apache::Session::Browseable::Store::Patroni';
    my $ds      = 'dbi:Pg:dbname=mocktest';

    # Helper to create PSGI app with given response
    my $make_app = sub {
        my ($json_data) = @_;
        return sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'application/json' ],
                [ JSON::to_json($json_data) ]
            ];
        };
    };

    # Test 1: Valid leader response
    {
        %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

        my $guard = LWP::Protocol::PSGI->register(
            $make_app->(
                {
                    members => [
                        {
                            role  => 'leader',
                            host  => '10.0.0.100',
                            port  => 5432,
                            state => 'running'
                        },
                        {
                            role  => 'replica',
                            host  => '10.0.0.101',
                            port  => 5432,
                            state => 'streaming'
                        }
                    ]
                }
            )
        );

        my $store = $package->new;
        $store->{_originalDataSource} = $ds;
        my $args = {
            DataSource => $ds,
            PatroniUrl => 'http://mock:8008/cluster'
        };

        my $stderr = '';
        my $result;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            $result = $store->checkMaster($args);
        }
        is( $result, 1, 'Valid leader: checkMaster returns 1' );
        like( $args->{DataSource}, qr/host=10\.0\.0\.100/,
            'Valid leader: correct host in DataSource' );
    }

    # Test 2: Split-brain detection (multiple leaders)
    {
        %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

        my $guard = LWP::Protocol::PSGI->register(
            $make_app->(
                {
                    members => [
                        {
                            role  => 'leader',
                            host  => '10.0.0.100',
                            port  => 5432,
                            state => 'running'
                        },
                        {
                            role  => 'leader',
                            host  => '10.0.0.101',
                            port  => 5432,
                            state => 'running'
                        }
                    ]
                }
            )
        );

        my $store = $package->new;
        $store->{_originalDataSource} = $ds;
        my $args = {
            DataSource => $ds,
            PatroniUrl => 'http://mock:8008/cluster'
        };

        my $stderr = '';
        my $result;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            $result = $store->checkMaster($args);
        }
        is( $result, 0, 'Split-brain: checkMaster returns 0' );
        like(
            $stderr,
            qr/Multiple leaders detected/,
            'Split-brain: warning message'
        );
    }

    # Test 3: Leader not in running state
    {
        %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

        my $guard = LWP::Protocol::PSGI->register(
            $make_app->(
                {
                    members => [
                        {
                            role  => 'leader',
                            host  => '10.0.0.100',
                            port  => 5432,
                            state => 'starting'
                        }
                    ]
                }
            )
        );

        my $store = $package->new;
        $store->{_originalDataSource} = $ds;
        my $args = {
            DataSource => $ds,
            PatroniUrl => 'http://mock:8008/cluster'
        };

        my $stderr = '';
        my $result;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            $result = $store->checkMaster($args);
        }
        is( $result, 0, 'Leader starting: checkMaster returns 0' );
        like(
            $stderr,
            qr/not in running state/,
            'Leader starting: warning message'
        );
    }

    # Test 4: Leader missing host
    {
        %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

        my $guard = LWP::Protocol::PSGI->register(
            $make_app->(
                {
                    members => [
                        {
                            role  => 'leader',
                            port  => 5432,
                            state => 'running'
                        }
                    ]
                }
            )
        );

        my $store = $package->new;
        $store->{_originalDataSource} = $ds;
        my $args = {
            DataSource => $ds,
            PatroniUrl => 'http://mock:8008/cluster'
        };

        my $stderr = '';
        my $result;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            $result = $store->checkMaster($args);
        }
        is( $result, 0, 'Leader missing host: checkMaster returns 0' );
        like(
            $stderr,
            qr/missing host or port/,
            'Leader missing host: warning message'
        );
    }

    # Test 5: No leader found
    {
        %Apache::Session::Browseable::Store::Patroni::patroniCache = ();

        my $guard = LWP::Protocol::PSGI->register(
            $make_app->(
                {
                    members => [
                        {
                            role  => 'replica',
                            host  => '10.0.0.101',
                            port  => 5432,
                            state => 'streaming'
                        }
                    ]
                }
            )
        );

        my $store = $package->new;
        $store->{_originalDataSource} = $ds;
        my $args = {
            DataSource => $ds,
            PatroniUrl => 'http://mock:8008/cluster'
        };

        my $stderr = '';
        my $result;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            $result = $store->checkMaster($args);
        }
        is( $result, 0, 'No leader: checkMaster returns 0' );
        like( $stderr, qr/No leader found/, 'No leader: warning message' );
    }

    # Clear cache
    %Apache::Session::Browseable::Store::Patroni::patroniCache = ();
}
