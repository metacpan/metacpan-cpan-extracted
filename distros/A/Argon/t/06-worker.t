use strict;
use warnings;
use AnyEvent::Loop; # Ensure the pure perl loop is loaded for testing
use Test::More;
use List::Util qw(sum);
use Coro;
use Sub::Override;
use Argon qw(:commands :logging);
use Argon::Message;
use Coro::ProcessPool;

SET_LOG_LEVEL($FATAL);

my @overrides = (
    Sub::Override->new('Coro::ProcessPool::process', sub {
        my ($pool, $f, $args) = @_;
        return $f->(@$args);
    }),
);

use_ok('Argon::Worker');

subtest '(standalone) positive path' => sub {
    my $w = new_ok('Argon::Worker') or BAIL_OUT;
    $w->init;

    ok(!$w->is_managed, 'is_managed false in standalone mode');
    ok($w->responds_to($CMD_QUEUE), 'dispatch configured correctly');

    my $task  = [sub { sum @_ }, [1, 2, 3]];
    my $msg   = Argon::Message->new(cmd => $CMD_QUEUE, payload => $task);
    my $reply = $w->dispatch($msg);

    is($reply->cmd, $CMD_COMPLETE, 'expected cmd');
    is($reply->payload, 6, 'expected payload');
};

subtest '(standalone) negative path' => sub {
    my $w = new_ok('Argon::Worker') or BAIL_OUT;
    $w->init;

    my $task  = [sub { die 'test error' }, []];
    my $msg   = Argon::Message->new(cmd => $CMD_QUEUE, payload => $task);
    my $reply = $w->dispatch($msg);

    is($reply->cmd, $CMD_ERROR, 'expected cmd');
    ok($reply->payload =~ /test error/, 'expected payload');
};

subtest '(managed) positive path' => sub {
    my $w = new_ok('Argon::Worker', [ manager => 'foo:9999', workers => 4 ]) or BAIL_OUT;
    ok($w->is_managed, 'is_managed true in managed mode');
    ok(!$w->is_registered, 'is_registered false before call to register');

    my $reg_msg;

    my @overrides = (
        Sub::Override->new('Argon::Stream::connect', sub { return bless {}, 'Argon::Stream' }),
        Sub::Override->new('Argon::Stream::write', sub { shift; $reg_msg = shift }),
        Sub::Override->new('Argon::Stream::read', sub {
            Argon::Message->new(
                cmd => $CMD_ACK,
                payload => { client_addr => 'foo:9997' },
            );
        }),
    );

    $w->_set_port(9998);
    $w->_set_host('bar');

    ok($w->register, 'register returns true on success');
    ok($w->is_registered, 'is_registered true after successful call to register');
    is($w->manager_client_addr, 'foo:9997', 'registration sets manager client address');
    ok(defined $reg_msg, 'registration message sent');
    isa_ok($reg_msg, 'Argon::Message', 'registration message isa Argon::Message');
    is($reg_msg->cmd, $CMD_REGISTER, 'registration message has correct command');
    is_deeply($reg_msg->payload, { host => 'bar', port => 9998, capacity => 4 }, 'registration message has correct payload');

    my $reply = $w->cmd_queue(Argon::Message->new(cmd => $CMD_QUEUE), 'asdf:1234');
    is($reply->cmd, $CMD_ERROR, 'cmd_queue fails in managed mode when msg source is not manager');
};

subtest '(managed) negative path' => sub {
    eval { Argon::Worker->new(manager => 'asdf') };
    ok($@, 'invalid manager address format triggers error');

    my $w = new_ok('Argon::Worker', [manager => 'foo:9999']) or BAIL_OUT;
    $w->_set_port(9999);
    $w->_set_host('bar');

    {
        my @overrides = (
            Sub::Override->new('Argon::Stream::connect', sub { die 'test msg' }),
        );

        ok(!$w->register, 'registration fails on connection failure');
        ok(!$w->is_registered, 'is_registered false after unsuccessful call to register');
    }

    my @overrides = (
        Sub::Override->new('Argon::Stream::connect', sub { return bless {}, 'Argon::Stream' }),
        Sub::Override->new('Argon::Stream::write', sub {}),
        Sub::Override->new('Argon::Stream::read', sub { Argon::Message->new(cmd => $CMD_ERROR, payload => 'test msg') }),
    );

    eval { $w->register };
    ok($@, 'registration failure from manager triggers an error');
    ok($@ =~ 'test msg', 'registration failure from manager propagates error message');
    ok(!$w->is_registered, 'is_registered false after unsuccessful call to register');
};

subtest '(managed) registration loop' => sub {
    my $w = new_ok('Argon::Worker', [manager => 'foo:9999']) or BAIL_OUT;
    $w->_set_port(9999);
    $w->_set_host('bar');

    local $Argon::POLL_INTERVAL = 0.5;

    my $mgr_client_addr = 'foo:9876';
    my $calls = 0;
    my $tries = 3;
    my $cb    = rouse_cb;

    my @overrides = (
        Sub::Override->new('Argon::Stream::write', sub {}),
        Sub::Override->new('Argon::Stream::read', sub {
            Argon::Message->new(
                cmd => $CMD_ACK,
                payload => { client_addr => $mgr_client_addr },
            );
        }),
        Sub::Override->new('Argon::Stream::connect', sub {
            if (++$calls >= $tries) {
                $cb->();
                return bless {}, 'Argon::Stream';
            } else {
                die 'test msg';
            }
        }),
    );

    my $loop = async { $w->register_loop };
    rouse_wait $cb;

    ok($w->is_registered, 'registration successful after retries');
    is($calls, $tries, 'registration retried expected number of times');

    $cb = rouse_cb;
    $w->client_disconnected($mgr_client_addr);
    rouse_wait $cb;

    is($calls, $tries + 1, 'registration triggered after client_disconnected called');
};

done_testing;
