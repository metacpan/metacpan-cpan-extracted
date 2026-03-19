# t/10-connection/unix-socket.t
#
# Test Unix domain socket connection support
#
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(run);
use Test2::V0;
use Async::Redis;
use IO::Socket::UNIX;

# --- Unit tests (no Redis needed) ---

subtest 'constructor stores path from explicit arg' => sub {
    my $redis = Async::Redis->new(path => '/tmp/redis.sock');

    is($redis->{path}, '/tmp/redis.sock', 'path stored');
    ok(!$redis->{host}, 'host not set for unix socket');
    ok(!$redis->{port}, 'port not set for unix socket');
};

subtest 'constructor stores path from URI' => sub {
    my $redis = Async::Redis->new(
        uri => 'redis+unix:///var/run/redis.sock',
    );

    is($redis->{path}, '/var/run/redis.sock', 'path stored from URI');
    ok(!$redis->{host}, 'host not set for unix socket URI');
    ok(!$redis->{port}, 'port not set for unix socket URI');
};

subtest 'constructor stores path and database from URI' => sub {
    my $redis = Async::Redis->new(
        uri => 'redis+unix:///var/run/redis.sock?db=3',
    );

    is($redis->{path}, '/var/run/redis.sock', 'path stored');
    is($redis->{database}, 3, 'database from URI query');
};

subtest 'connect attempts AF_UNIX for path' => sub {
    # Use a path that doesn't exist — we expect a connection error,
    # but the error should be about the socket, NOT hostname resolution
    my $redis = Async::Redis->new(
        path            => '/tmp/nonexistent-redis-test.sock',
        connect_timeout => 1,
    );

    my $error;
    eval { run { $redis->connect } } or $error = $@;

    ok($error, 'connect fails for nonexistent socket');
    unlike("$error", qr/Cannot resolve host/, 'not a hostname resolution error');
    unlike("$error", qr/localhost/, 'not trying localhost');
};

# --- Integration tests (require Redis on Unix socket) ---

SKIP: {
    my $socket_path = $ENV{REDIS_SOCKET} // '/tmp/redis-test-unix/redis.sock';

    skip 'Redis unix socket not connectable (start docker-compose or set REDIS_SOCKET)', 3
        unless -S $socket_path
        && IO::Socket::UNIX->new(Peer => $socket_path, Type => IO::Socket::UNIX::SOCK_STREAM());

    subtest 'connect and PING via unix socket' => sub {
        my $redis = Async::Redis->new(
            path            => $socket_path,
            connect_timeout => 2,
        );

        run { $redis->connect };
        ok($redis->is_connected, 'connected via unix socket');

        my $pong = run { $redis->ping };
        is($pong, 'PONG', 'PING via unix socket');

        $redis->disconnect;
    };

    subtest 'GET/SET via unix socket' => sub {
        my $redis = Async::Redis->new(
            path            => $socket_path,
            connect_timeout => 2,
        );

        run { $redis->connect };
        run { $redis->set('unix:test:key', 'socket_value') };
        my $val = run { $redis->get('unix:test:key') };
        is($val, 'socket_value', 'GET/SET works via unix socket');

        run { $redis->del('unix:test:key') };
        $redis->disconnect;
    };

    subtest 'connect via unix socket URI' => sub {
        my $redis = Async::Redis->new(
            uri             => "redis+unix://$socket_path",
            connect_timeout => 2,
        );

        run { $redis->connect };
        my $pong = run { $redis->ping };
        is($pong, 'PONG', 'PING via unix socket URI');

        $redis->disconnect;
    };
}

done_testing;
