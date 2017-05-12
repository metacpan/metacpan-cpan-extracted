use strict;
use Test::More;

BEGIN
{
    eval { 
        require Cache::Memcached;
    };
    if ($@) {
        plan(skip_all => "This test requires Cache::Memcached");
    } else {
        if (! $ENV{MEMCACHED_SERVER} ) {
            # check if localhost:11211 is accessible
            eval {
                require IO::Socket::INET;
                my $socket = IO::Socket::INET->new(
                    PeerAddr => '127.0.0.1',
                    PeerPort => 11211,
                );
                if (! $@) {
                    $ENV{MEMCACHED_SERVER} = '127.0.0.1:11211';
                }
            };
        }

        if (! $ENV{MEMCACHED_SERVER}) {
            plan(skip_all => "Define MEMCACHED_SERVER to run this test");
        }

        $ENV{MEMCACHED_NAMESPACE} ||= join('-', rand(), {}, $$);

        plan(tests => 30);
    }

    use_ok("Data::Valve");
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval => 3,
        bucket_store => {
            module => "Memcached",
            args   => {
                store => {
                    args => {
                        servers => [ $ENV{MEMCACHED_SERVER} ],
                        namespace => $ENV{MEMCACHED_NAMESPACE},
                    }
                }
            }
        }
    );

    isa_ok( $valve->bucket_store, "Data::Valve::BucketStore::Memcached" );
    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(), "this try should fail" );

    diag("sleeping for 3 seconds...");
    sleep 3;

    ok( $valve->try_push(), "try after 3 seconds should work");
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval => 3,
        bucket_store => {
            module => "Memcached",
            args   => {
                store => {
                    args => {
                        servers => [ $ENV{MEMCACHED_SERVER} ],
                        namespace => $ENV{MEMCACHED_NAMESPACE},
                    }
                }
            }
        }
    );
    $valve->reset();

    isa_ok( $valve->bucket_store, "Data::Valve::BucketStore::Memcached" );
    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(), "this try should fail" );
    $valve->reset();

    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval => 3,
        bucket_store => {
            module => "Memcached",
            args   => {
                store => {
                    args => {
                        servers => [ $ENV{MEMCACHED_SERVER} ],
                        namespace => $ENV{MEMCACHED_NAMESPACE},
                    }
                }
            }
        }
    );
    $valve->fill();

    ok( ! $valve->try_push(), "this try should fail" );
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval => 3,
        bucket_store => {
            module => "Memcached",
            args   => {
                store => {
                    args => {
                        servers => [ $ENV{MEMCACHED_SERVER} ],
                        namespace => $ENV{MEMCACHED_NAMESPACE},
                    }
                }
            }
        }
    );
    $valve->reset();

    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(key => "foo"), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(key => "foo"), "this try should fail" );
    ok( $valve->try_push(key => "bar"), "this try should succeed" );

    diag("sleeping for 3 seconds...");
    sleep 3;

    ok( $valve->try_push(key => "foo"), "try after 3 seconds should work");
}

