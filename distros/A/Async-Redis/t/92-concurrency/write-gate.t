use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Async::Redis;

# Unit-style test; no real connection needed. We exercise the gate
# primitives directly on a bare client object.

my $c = Async::Redis->new(host => 'x', port => 1);
$c->{_socket_live} = 1;   # pretend the socket is up so step 2 passes

subtest 'serial acquire/release works' => sub {
    (async sub {
        my @order;

        my $t1 = (async sub {
            await $c->_acquire_write_lock;
            push @order, 'a-in';
            await Future::IO->sleep(0.02);
            push @order, 'a-out';
            $c->_release_write_lock;
        })->();

        my $t2 = (async sub {
            # Give t1 a head start
            await Future::IO->sleep(0.005);
            await $c->_acquire_write_lock;
            push @order, 'b-in';
            push @order, 'b-out';
            $c->_release_write_lock;
        })->();

        await Future->needs_all($t1, $t2);
        is \@order, ['a-in', 'a-out', 'b-in', 'b-out'],
            'second acquire waits for first release';
    })->()->get;
};

subtest '_acquire_write_lock waits for _fatal_in_progress' => sub {
    (async sub {
        my $done_during_fatal;

        $c->{_fatal_in_progress} = 1;

        my $t = (async sub {
            await $c->_acquire_write_lock;
            $done_during_fatal = 1;
            $c->_release_write_lock;
        })->();

        # Let the task spin
        await Future::IO->sleep(0.02);
        ok !$done_during_fatal, 'did not proceed while fatal in progress';

        $c->{_fatal_in_progress} = 0;
        await $t;
        ok $done_during_fatal, 'proceeded once fatal cleared';
    })->()->get;
};

done_testing;
