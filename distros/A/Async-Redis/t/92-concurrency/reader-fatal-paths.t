use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(blessed);
use Future::AsyncAwait;
use Future::IO;
use Async::Redis;

subtest 'detached inflight futures fail with typed error, not generic cancellation' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;
    my $f1 = Future->new;
    my $f2 = Future->new;
    $c->{inflight} = [
        { future => $f1, cmd => 'GET', args => ['x'], deadline => 0 },
        { future => $f2, cmd => 'SET', args => ['y', 'z'], deadline => 0 },
    ];

    my $err = Async::Redis::Error::Timeout->new(
        message => 'test timeout',
        timeout => 5,
    );
    $c->_reader_fatal($err);

    ok $f1->is_failed, 'f1 failed';
    my ($e1) = $f1->failure;
    ok blessed($e1) && $e1->isa('Async::Redis::Error::Timeout'),
        'f1 carries the typed error, not cancellation';

    ok $f2->is_failed, 'f2 failed';
    my ($e2) = $f2->failure;
    ok blessed($e2) && $e2->isa('Async::Redis::Error::Timeout'),
        'f2 also carries the typed error';

    is scalar @{$c->{inflight}}, 0, 'inflight drained';
    is $c->{_socket_live}, 0, '_socket_live cleared';
    is $c->{connected},    0, 'connected cleared';
};

subtest 'reentrance during same call is a no-op (idempotence guard)' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;
    my $on_disc_calls = 0;

    # Set up a callback that tries to call _reader_fatal again during
    # _reader_fatal. The guard should prevent a second on_disconnect fire.
    $c->{on_disconnect} = sub {
        $on_disc_calls++;
        $c->_reader_fatal(Async::Redis::Error::Connection->new(
            message => 'reentrant', host => 'x', port => 1,
        ));
    };

    $c->_reader_fatal(Async::Redis::Error::Connection->new(
        message => 'first', host => 'x', port => 1,
    ));

    is $on_disc_calls, 1, 'on_disconnect fired exactly once';
    is $c->{_fatal_in_progress}, 0, 'guard cleared after transition';
};

subtest 'second fatal after first completes is a fresh transition' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;
    my $on_disc_calls = 0;
    $c->{on_disconnect} = sub { $on_disc_calls++ };

    $c->_reader_fatal(Async::Redis::Error::Connection->new(
        message => 'first', host => 'x', port => 1,
    ));

    # Re-arm _socket_live and connected to simulate a reconnect, then
    # fatal again. This should count as a NEW transition.
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;
    $c->_reader_fatal(Async::Redis::Error::Connection->new(
        message => 'second', host => 'x', port => 1,
    ));

    is $on_disc_calls, 2, 'on_disconnect fired twice (once per transition)';
};

subtest 'on_disconnect skipped when not previously connected' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 0;   # e.g., during handshake
    my $on_disc_calls = 0;
    $c->{on_disconnect} = sub { $on_disc_calls++ };

    $c->_reader_fatal(Async::Redis::Error::Connection->new(
        message => 'handshake failed', host => 'x', port => 1,
    ));

    is $on_disc_calls, 0, 'on_disconnect not fired for pre-connected fatal';
};

subtest 'auto-pipeline queued futures also fail with typed error' => sub {
    require Async::Redis::AutoPipeline;
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;

    my $ap = Async::Redis::AutoPipeline->new(
        redis     => $c,
        max_depth => 10,
    );
    $c->{_auto_pipeline} = $ap;

    # Queue a command without flushing. The AutoPipeline's public method
    # for this varies; if ->submit doesn't exist, use ->push or
    # directly push onto the queue. Adapt to what exists.
    my $future = Future->new;
    push @{$ap->{_queue}}, { cmd => ['GET', 'k'], future => $future };

    my $err = Async::Redis::Error::Connection->new(
        message => 'boom', host => 'x', port => 1,
    );
    $c->_reader_fatal($err);

    ok $future->is_failed, 'queued auto-pipeline future failed';
    my ($e) = $future->failure;
    ok blessed($e) && $e->isa('Async::Redis::Error::Connection'),
        'carries the typed error';
    is scalar @{$ap->{_queue}}, 0, 'queue drained';
};

subtest 'a dying on_disconnect does not wedge the fatal guard' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    $c->{_socket_live} = 1;
    $c->{connected}    = 1;
    $c->{on_disconnect} = sub { die "intentional test failure" };

    my $died = eval {
        $c->_reader_fatal(Async::Redis::Error::Connection->new(
            message => 'x', host => 'x', port => 1,
        ));
        0;
    } || $@;

    ok $died, 'rethrew the callback exception';
    is $c->{_fatal_in_progress}, 0,
        'guard was cleared even though the callback died';
};

done_testing;
