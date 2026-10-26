use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield stop];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Future;
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;

# remove_waiter unregisters a parked fiber so the primitive will never wake it.
# A removed waiter stays parked forever, and its Perl object must live until the
# process ends (destroying a mid-park fiber is safe since the C-level coroutine fix in t/046,
# but a removed waiter is never resumed, so its object is stashed in @parked and
# reclaimed by the runtime's own cleanup() during global destruction, as before).
# The block's run is ended with stop() so the deadlock detector is never reached.
my @parked;
subtest 'Semaphore: remove_waiter unregisters a parked fiber' => sub {
    my $sem  = Acme::Parataxis::Semaphore->new( count => 0 );
    my $done = '';
    async {
        my $w = fiber {
            $sem->down;
            $done .= 'W';
        };
        push @parked, $w;
        is $sem->waiters,                  1, 'start with one parked fiber';
        is $sem->remove_waiter( $w->fid ), 1, 'remove_waiter drops the parked fiber';
        is $sem->waiters,                  0, 'waiters is empty after removal';
        is $sem->remove_waiter( $w->fid ), 0, 'removing again returns 0';
        $sem->up;          # wakes nobody anymore
        yield for 1 .. 3;
        is $done, '', 'the removed fiber was not resumed by up';
        my $z = fiber {    # a live waiter still works afterwards
            $sem->down;
            $done .= 'Z';
        };
        $sem->up;
        $z->await;
        is $done, 'Z', 'a later waiter is still woken and runs';
        stop;
    };
    is $done, 'Z', 'only the live waiter completed';
};
subtest 'Signal: remove_waiter drops a parked fiber by id' => sub {
    my $sig  = Acme::Parataxis::Signal->new( count => false );
    my $done = '';
    async {
        my $w = fiber {
            $sig->wait;
            $done .= 'W';
        };
        push @parked, $w;
        is $sig->awaited,                  1, 'one fiber parked on the signal';
        is $sig->remove_waiter( $w->fid ), 1, 'remove_waiter drops the parked fiber';
        is $sig->remove_waiter( $w->fid ), 0, 'removing again returns 0';
        is $sig->awaited,                  0, 'no waiters after removal';
        $sig->send;    # with nobody waiting the signal is remembered
        ok $sig->count, 'send is remembered (nobody waiting)';
        is $done, '', 'removed fiber was not resumed by send';
        my $z = fiber {
            $sig->wait;
            $done .= 'Z';
        };
        is $done,         'Z', 'a later wait consumes the remembered signal instantly';
        is $sig->awaited, 0,   'no waiters after the remembered signal is consumed';
        stop;
    };
    is $done, 'Z', 'only the live waiter ran';
};
subtest 'Signal: remove_waiter drops a callback by identity' => sub {
    my $sig   = Acme::Parataxis::Signal->new( count => false );
    my $fired = 0;
    my $cb    = sub { $fired++ };
    my $other = sub {1};
    $sig->wait($cb);
    is $sig->awaited,               1, 'callback registered';
    is $sig->remove_waiter($other), 0, 'a different callback identity does not match';
    is $sig->remove_waiter(9999),   0, 'a fiber id does not match a callback waiter';
    is $sig->remove_waiter($cb),    1, 'remove_waiter drops the callback';
    is $sig->remove_waiter($cb),    0, 'removing again returns 0';
    is $sig->awaited,               0, 'no waiters left';
    $sig->send;
    is $fired, 0, 'removed callback was not invoked by send';
    ok $sig->count, 'send remembered the signal (nobody waiting)';
};
subtest 'Future: remove_waiter unregisters a parked awaiter' => sub {
    my $f   = Acme::Parataxis::Future->new;
    my $got = 'sentinel';
    async {
        my $w = fiber { $got = $f->await };
        push @parked, $w;
        is $f->remove_waiter( $w->fid ), 1, 'remove_waiter drops the parked awaiter';
        is $f->remove_waiter( $w->fid ), 0, 'removing again returns 0';
        $f->set_result('x');
        yield for 1 .. 3;
        is $got, 'sentinel', 'removed awaiter was not resumed by set_result';
        my $z = fiber { $got = $f->await };
        is $got, 'x', 'a later await sees the already-ready result';
        stop;
    };
    is $got, 'x', 'sanity: only the live awaiter ran';
};
subtest 'Channel: remove_waiter drops a blocked getter' => sub {
    my $ch  = Acme::Parataxis::Channel->new( capacity => 1 );
    my @got = ();
    async {
        my $w = fiber { push @got, $ch->get };    # channel empty: parks the getter
        push @parked, $w;
        is $ch->remove_waiter( $w->fid ), 1, 'remove_waiter drops the blocked getter';
        is $ch->remove_waiter( $w->fid ), 0, 'removing again returns 0';
        $ch->put('v');                            # buffered; no getter left to wake
        is $ch->size, 1, 'value is buffered after put';
        yield for 1 .. 3;
        is @got, 0, 'removed getter was not resumed by put';
        my $z = fiber { push @got, $ch->get };    # a live getter drains it
        $z->await;
        is \@got, ['v'], 'a later getter receives the buffered value';
        stop;
    };
    is \@got, ['v'], 'only the live getter ran';
};
subtest 'Channel: remove_waiter drops a blocked putter' => sub {
    my $ch      = Acme::Parataxis::Channel->new( capacity => 1 );
    my $traffic = '';
    $ch->put('full');    # capacity reached: putters must park from here on
    async {
        my $w = fiber {
            $ch->put('extra');
            $traffic .= 'W';
        };
        push @parked, $w;
        is $ch->remove_waiter( $w->fid ), 1, 'remove_waiter drops the blocked putter';
        is $ch->remove_waiter( $w->fid ), 0, 'removing again returns 0';
        $traffic .= 'M';
        my $v = fiber { $traffic .= $ch->get };    # drains "full", freeing a permit
        $v->await;
        is $traffic, 'Mfull', 'removed putter did not wake when space was freed';
        stop;
    };
    is $traffic, 'Mfull', 'only the drainer ran';
};
#
done_testing;
