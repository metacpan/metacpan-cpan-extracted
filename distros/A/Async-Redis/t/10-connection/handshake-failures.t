use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Async::Redis;

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

subtest 'wrong password dies with typed error, connected remains 0' => sub {
    (async sub {
        my $c = Async::Redis->new(
            host     => $ENV{REDIS_HOST},
            port     => $ENV{REDIS_PORT} // 6379,
            password => 'definitely-wrong-password',
        );
        my $ok = eval { await $c->connect; 1 };
        my $err = $@ unless $ok;
        ok !$ok, 'connect died';
        isa_ok $err, ['Async::Redis::Error'], 'typed error';
        is $c->{connected},    0, 'connected == 0';
        is $c->{_socket_live}, 0, '_socket_live == 0';
        ok !$c->{socket},         'socket torn down';
    })->()->get;
};

subtest 'invalid SELECT db dies with typed error, connected remains 0' => sub {
    (async sub {
        my $c = Async::Redis->new(
            host     => $ENV{REDIS_HOST},
            port     => $ENV{REDIS_PORT} // 6379,
            database => 99999,
        );
        my $ok = eval { await $c->connect; 1 };
        ok !$ok, 'connect died on SELECT';
        is $c->{connected}, 0, 'connected == 0 after handshake failure';
    })->()->get;
};

subtest 'password "0" is stored as defined, not skipped' => sub {
    # Defined-check test: verify password is preserved as "0" after
    # construction. Deeper behavioral coverage needs a real server
    # configured with password "0" which is not portable.
    my $c = Async::Redis->new(host => 'x', port => 1, password => '0');
    is defined $c->{password}, 1, 'password defined';
    is $c->{password}, '0', 'password stored as "0"';
};

done_testing;
