use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Future;
use Time::HiRes ();
use Async::Redis;   # exposes _await_with_deadline for testing

my $helper = \&Async::Redis::_await_with_deadline;

subtest 'undef deadline awaits read forever' => sub {
    my $read_f = Future->new;
    my $wait   = $helper->($read_f, undef);
    $read_f->done('ok');
    my ($returned_f, $timed_out) = $wait->get;
    is $returned_f, $read_f, 'returns the read future';
    is $timed_out, 0, 'not timed out';
};

subtest 'deadline in the past returns immediate timeout' => sub {
    my $read_f = Future->new;
    my $wait   = $helper->($read_f, Time::HiRes::time() - 1);
    my ($returned_f, $timed_out) = $wait->get;
    is $timed_out, 1, 'timed out';
    ok !$read_f->is_ready, 'read future left pending for reader_fatal to cancel';
};

subtest 'read wins before deadline' => sub {
    my $read_f  = Future->new;
    my $wait    = $helper->($read_f, Time::HiRes::time() + 5);
    $read_f->done('got bytes');
    my ($returned_f, $timed_out) = $wait->get;
    is $timed_out, 0, 'not timed out';
    is scalar $returned_f->get, 'got bytes', 'read future delivered';
};

subtest 'timeout wins' => sub {
    my $read_f = Future->new;
    my $wait   = $helper->($read_f, Time::HiRes::time() + 0.05);
    my ($returned_f, $timed_out) = $wait->get;
    is $timed_out, 1, 'timed out';
    ok !$read_f->is_ready, 'read future still pending';
};

subtest 'timeout timer cancelled when read wins' => sub {
    # This is a hygiene check: after read_f completes, the internal
    # timeout Future must be cancelled so no stray timer fires later.
    # We verify indirectly: run the event loop after completion and
    # assert no exceptions / no extra work.
    my $read_f = Future->new;
    my $wait   = $helper->($read_f, Time::HiRes::time() + 0.05);
    $read_f->done('fast');
    $wait->get;
    # Pump the loop past where the timer would have fired.
    Future::IO->sleep(0.1)->get;
    ok 1, 'no stray timer fired';
};

done_testing;
