use strict;
use warnings;
use AnyEvent::Loop; # Ensure the pure perl loop is loaded for testing
use Test::More;
use Coro;
use Sub::Override;
use Argon::Message;
use Argon qw(:commands :logging);
use Argon::Client;
use Argon::Stream;

SET_LOG_LEVEL($FATAL);

use_ok('Argon::Manager') or BAIL_OUT;

# Create a new manager
my $m = new_ok('Argon::Manager', [port => '4321', host => 'test', queue_size => 10]) or BAIL_OUT;
$m->init;

ok($m->responds_to($CMD_QUEUE), 'manager responds to CMD_QUEUE');
ok($m->responds_to($CMD_REGISTER), 'manager responds to CMD_REGISTER');

# Queue fails with no capacity
{
    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_QUEUE));
    is($reply->cmd, $CMD_REJECTED, 'queue fails with no capacity');
}

# Registration succeeds
{
    my $monitor_called;

    my @overrides = (
        Sub::Override->new('Argon::Manager::start_monitor', sub { $monitor_called = 1 }),
        Sub::Override->new('Argon::Stream::connect', sub { bless {}, 'Argon::Stream' }),
        Sub::Override->new('Argon::Stream::addr', sub { 'blah:4321' }),
        Sub::Override->new('Argon::Client::_build_read_loop', sub {async {}}),
    );

    my $msg = Argon::Message->new(
        cmd     => $CMD_REGISTER,
        key     => 'test',
        payload => {
            host     => 'foo',
            port     => '1234',
            capacity => 4,
        }
    );

    my $reply = $m->dispatch($msg);

    is($reply->cmd, $CMD_ACK, 'register acks');
    is($reply->payload->{client_addr}, 'blah:4321', 'register replies with correct payload');
    is($m->capacity, 4, 'register incs capacity');
    is($m->current_capacity, 4, 'register ups sem');
    ok($m->has_worker('test'), 'has_worker true after register');
    ok($monitor_called, 'register starts monitoring worker connection');
}

# Queue succeeds with registered worker
{
    my @overrides = (
        Sub::Override->new('Argon::Client::send', sub { return $_[1]->reply(cmd => $CMD_COMPLETE, payload => 42) }),
    );

    my $ack = $m->dispatch(Argon::Message->new(cmd => $CMD_QUEUE));
    is($ack->cmd, $CMD_ACK, 'queue succeeds with registered worker');

    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_COLLECT, payload => $ack->id));
    is($reply->payload, 42, 'queue returns expected result from worker client');
}

# Status
{
    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_STATUS));
    is($reply->cmd, $CMD_COMPLETE, 'correct reply status');

    my $expected = {
        workers          => 1,
        total_capacity   => 4,
        current_capacity => 4,
        queue_length     => 0,
        pending          => {test => {}},
    };

    is_deeply($reply->payload, $expected, 'expected status');
}

# Queue fails when max capacity reached
{
    my @overrides = (
        Sub::Override->new('Argon::Manager::queue_len', sub { 11 }),
    );

    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_QUEUE));
    is($reply->cmd, $CMD_REJECTED, 'queue fails with no capacity when queue full');
}

# Status
{
    my @overrides = (
        Sub::Override->new('Argon::Manager::queue_len',        sub { 11 }),
        Sub::Override->new('Argon::Manager::current_capacity', sub {  0 }),
        Sub::Override->new('Argon::Tracker::all_pending',      sub { qw(foo bar baz bat) }),
        Sub::Override->new('Argon::Tracker::age',              sub { 42 }),
    );

    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_STATUS));
    is($reply->cmd, $CMD_COMPLETE, 'correct reply status');

    my $expected = {
        workers          => 1,
        total_capacity   => 4,
        current_capacity => 0,
        queue_length     => 11,
        pending          => {
            test => {
                foo => 42,
                bar => 42,
                baz => 42,
                bat => 42,
            },
        },
    };

    is_deeply($reply->payload, $expected, 'expected status');
}

# Deregistration results in capacity reduction
{
    $m->deregister('test');
    is($m->capacity, 0, 'worker disconnect removes capacity');
    is($m->current_capacity, 0, 'worker disconnect adjusts sem');
    ok(!$m->has_worker('test'), 'worker deregistered');
}

# Queue fails with degraded capacity
{
    my $reply = $m->dispatch(Argon::Message->new(cmd => $CMD_QUEUE));
    is($reply->cmd, $CMD_REJECTED, 'queue fails with no capacity after dereg');
}

done_testing;
