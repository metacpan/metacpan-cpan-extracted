# t/01-unit/error.t
use strict;
use warnings;
use Test2::V0;

use Async::Redis::Error;
use Async::Redis::Error::Connection;
use Async::Redis::Error::Timeout;
use Async::Redis::Error::Protocol;
use Async::Redis::Error::Redis;
use Async::Redis::Error::Disconnected;

subtest 'Error base class' => sub {
    my $e = Async::Redis::Error->new(message => 'test error');
    ok($e->isa('Async::Redis::Error'), 'isa Error');
    is($e->message, 'test error', 'message accessor');
    like("$e", qr/test error/, 'stringifies to message');
};

subtest 'Error throw class method' => sub {
    my $died;
    eval {
        Async::Redis::Error->throw(message => 'thrown error');
    };
    $died = $@;
    ok($died, 'throw dies');
    ok($died->isa('Async::Redis::Error'), 'thrown error is Error object');
    is($died->message, 'thrown error', 'message correct');
};

subtest 'Connection error' => sub {
    my $e = Async::Redis::Error::Connection->new(
        message => 'connection lost',
        host    => 'localhost',
        port    => 6379,
        reason  => 'timeout',
    );
    ok($e->isa('Async::Redis::Error'), 'isa base Error');
    ok($e->isa('Async::Redis::Error::Connection'), 'isa Connection');
    is($e->host, 'localhost', 'host accessor');
    is($e->port, 6379, 'port accessor');
    is($e->reason, 'timeout', 'reason accessor');
    like("$e", qr/connection lost/, 'stringifies');
};

subtest 'Timeout error' => sub {
    my $e = Async::Redis::Error::Timeout->new(
        message        => 'request timed out',
        command        => ['GET', 'mykey'],
        timeout        => 5,
        maybe_executed => 0,
    );
    ok($e->isa('Async::Redis::Error'), 'isa base Error');
    ok($e->isa('Async::Redis::Error::Timeout'), 'isa Timeout');
    is($e->command, ['GET', 'mykey'], 'command accessor');
    is($e->timeout, 5, 'timeout accessor');
    ok(!$e->maybe_executed, 'maybe_executed false');

    my $e2 = Async::Redis::Error::Timeout->new(
        message        => 'timed out after write',
        maybe_executed => 1,
    );
    ok($e2->maybe_executed, 'maybe_executed true');
};

subtest 'Protocol error' => sub {
    my $e = Async::Redis::Error::Protocol->new(
        message => 'unexpected response type',
        data    => '+OK',
    );
    ok($e->isa('Async::Redis::Error'), 'isa base Error');
    ok($e->isa('Async::Redis::Error::Protocol'), 'isa Protocol');
    is($e->data, '+OK', 'data accessor');
};

subtest 'Redis error' => sub {
    my $e = Async::Redis::Error::Redis->new(
        message => 'WRONGTYPE Operation against a key holding the wrong kind of value',
        type    => 'WRONGTYPE',
    );
    ok($e->isa('Async::Redis::Error'), 'isa base Error');
    ok($e->isa('Async::Redis::Error::Redis'), 'isa Redis');
    is($e->type, 'WRONGTYPE', 'error type');

    # Predicate methods
    ok($e->is_wrongtype, 'is_wrongtype true');
    ok(!$e->is_oom, 'is_oom false');
    ok(!$e->is_busy, 'is_busy false');
    ok(!$e->is_loading, 'is_loading false');
    ok($e->is_fatal, 'WRONGTYPE is fatal');
};

subtest 'Redis error predicates' => sub {
    my %cases = (
        WRONGTYPE => { is_wrongtype => 1, is_fatal => 1 },
        OOM       => { is_oom => 1, is_fatal => 1 },
        BUSY      => { is_busy => 1, is_fatal => 0 },
        LOADING   => { is_loading => 1, is_fatal => 0 },
        NOSCRIPT  => { is_noscript => 1, is_fatal => 1 },
        READONLY  => { is_readonly => 1, is_fatal => 0 },
    );

    for my $type (sort keys %cases) {
        my $e = Async::Redis::Error::Redis->new(
            message => "$type error",
            type    => $type,
        );
        my $expected = $cases{$type};

        for my $pred (qw(is_wrongtype is_oom is_busy is_loading is_noscript is_readonly)) {
            my $want = $expected->{$pred} // 0;
            is(!!$e->$pred, !!$want, "$type: $pred = $want");
        }
        is(!!$e->is_fatal, !!$expected->{is_fatal}, "$type: is_fatal = $expected->{is_fatal}");
    }
};

subtest 'Redis error from_message parser' => sub {
    my $e = Async::Redis::Error::Redis->from_message(
        'WRONGTYPE Operation against a key holding the wrong kind of value'
    );
    is($e->type, 'WRONGTYPE', 'type parsed from message');
    like($e->message, qr/WRONGTYPE/, 'message preserved');

    my $e2 = Async::Redis::Error::Redis->from_message('ERR unknown command');
    is($e2->type, 'ERR', 'ERR type parsed');
};

subtest 'Disconnected error' => sub {
    my $e = Async::Redis::Error::Disconnected->new(
        message    => 'command queue full',
        queue_size => 1000,
    );
    ok($e->isa('Async::Redis::Error'), 'isa base Error');
    ok($e->isa('Async::Redis::Error::Disconnected'), 'isa Disconnected');
    is($e->queue_size, 1000, 'queue_size accessor');
};

done_testing;
