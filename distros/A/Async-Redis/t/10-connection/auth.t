# t/10-connection/auth.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

# Helper: await a Future and return its result (throws on failure)

subtest 'constructor accepts auth parameters' => sub {
    my $redis = Async::Redis->new(
        host        => 'localhost',
        password    => 'secret',
        username    => 'myuser',
        database    => 5,
        client_name => 'myapp',
    );

    is($redis->{password}, 'secret', 'password stored');
    is($redis->{username}, 'myuser', 'username stored');
    is($redis->{database}, 5, 'database stored');
    is($redis->{client_name}, 'myapp', 'client_name stored');
};

subtest 'URI parsed for auth' => sub {
    my $redis = Async::Redis->new(
        uri => 'redis://user:pass@localhost:6380/3',
    );

    is($redis->{username}, 'user', 'username from URI');
    is($redis->{password}, 'pass', 'password from URI');
    is($redis->{database}, 3, 'database from URI');
    is($redis->{host}, 'localhost', 'host from URI');
    is($redis->{port}, 6380, 'port from URI');
};

subtest 'URI TLS detected' => sub {
    my $redis = Async::Redis->new(
        uri => 'rediss://localhost',
    );

    ok($redis->{tls}, 'TLS enabled from rediss://');
};

# Tests requiring Redis with specific configuration
SKIP: {
    my $test_redis = eval {
        my $r = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 3 unless $test_redis;
    $test_redis->disconnect;

    subtest 'SELECT database works' => sub {
        my $redis = Async::Redis->new(
            host     => $ENV{REDIS_HOST} // 'localhost',
            database => 1,
        );

        run { $redis->connect };

        # Set a key in database 1
        run { $redis->set('auth:test:db1', 'value1') };

        # Verify we're in database 1
        my $val = run { $redis->get('auth:test:db1') };
        is($val, 'value1', 'key accessible in db 1');

        run { $redis->del('auth:test:db1') };
        $redis->disconnect;

        # Connect to database 0, key should not exist
        my $redis2 = Async::Redis->new(
            host     => $ENV{REDIS_HOST} // 'localhost',
            database => 0,
        );
        run { $redis2->connect };

        my $val2 = run { $redis2->get('auth:test:db1') };
        is($val2, undef, 'key not in db 0');

        $redis2->disconnect;
    };

    subtest 'CLIENT SETNAME works' => sub {
        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            client_name => 'test-client-12345',
        );

        run { $redis->connect };

        # Verify client name was set
        my $name = run { $redis->command('CLIENT', 'GETNAME') };
        is($name, 'test-client-12345', 'client name set');

        $redis->disconnect;
    };

    subtest 'auth replayed on reconnect' => sub {
        my $connect_count = 0;

        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            database    => 2,
            client_name => 'reconnect-test',
            reconnect   => 1,
            on_connect  => sub { $connect_count++ },
        );

        run { $redis->connect };
        is($connect_count, 1, 'connected once');

        # Set key in db 2
        run { $redis->set('auth:reconnect:key', 'val') };

        # Force disconnect
        close $redis->{socket};
        $redis->{connected} = 0;

        # Command should reconnect and still be in db 2
        my $val = run { $redis->get('auth:reconnect:key') };
        is($val, 'val', 'still in database 2 after reconnect');
        is($connect_count, 2, 'reconnected');

        # Verify client name restored
        my $name = run { $redis->command('CLIENT', 'GETNAME') };
        is($name, 'reconnect-test', 'client name restored');

        run { $redis->del('auth:reconnect:key') };
        $redis->disconnect;
    };
}

# Password auth tests require Redis configured with requirepass
SKIP: {
    skip "Set REDIS_AUTH_HOST and REDIS_AUTH_PASS to test auth", 2
        unless $ENV{REDIS_AUTH_HOST} && $ENV{REDIS_AUTH_PASS};

    subtest 'password authentication works' => sub {
        my $redis = Async::Redis->new(
            host     => $ENV{REDIS_AUTH_HOST},
            password => $ENV{REDIS_AUTH_PASS},
        );

        run { $redis->connect };
        my $pong = run { $redis->ping };
        is($pong, 'PONG', 'authenticated successfully');

        $redis->disconnect;
    };

    subtest 'wrong password fails' => sub {
        my $redis = Async::Redis->new(
            host     => $ENV{REDIS_AUTH_HOST},
            password => 'wrongpassword',
        );

        my $error;
        my $f = $redis->connect;
        get_loop()->await($f);
        eval { $f->get };
        $error = $@;

        ok($error, 'connection failed');
        like("$error", qr/auth|password|denied/i, 'error mentions auth');
    };
}

# ACL auth tests require Redis 6+ with ACL configured
SKIP: {
    skip "Set REDIS_ACL_HOST, REDIS_ACL_USER, REDIS_ACL_PASS to test ACL", 1
        unless $ENV{REDIS_ACL_HOST} && $ENV{REDIS_ACL_USER} && $ENV{REDIS_ACL_PASS};

    subtest 'ACL authentication works' => sub {
        my $redis = Async::Redis->new(
            host     => $ENV{REDIS_ACL_HOST},
            username => $ENV{REDIS_ACL_USER},
            password => $ENV{REDIS_ACL_PASS},
        );

        run { $redis->connect };
        my $pong = run { $redis->ping };
        is($pong, 'PONG', 'ACL authenticated successfully');

        $redis->disconnect;
    };
}

done_testing;
