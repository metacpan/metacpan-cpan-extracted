use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await yield await_sleep on_wake];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Future;
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;
subtest 'wait_reason is undef for a fiber that never parks' => sub {
    async {
        my $f = fiber { yield for 1 .. 3; return 5 };
        ok !defined $f->wait_reason, 'no reason while merely cooperatively yielded';
        is $f->await, 5, 'the fiber still completes';
    };
};
subtest 'await_sleep records reason and caller location' => sub {
    my ( $r, $line );
    async {
        my $f = fiber {
            $line = __LINE__ + 1;
            await_sleep(50);
        };
        $r = $f->wait_reason;
        is $r->[0], 'await_sleep', 'reason names await_sleep';
        is $r->[1], __FILE__,      'file is the awaiting caller';
        is $r->[2], $line,         'line is the awaiting call site';
        $f->await;
        ok !defined $f->wait_reason, 'reason is cleared once the fiber resumes';
    };
};
subtest 'semaphore down records reason and caller location' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my ( $r, $line );
    async {
        my $f = fiber {
            $line = __LINE__ + 1;
            $sem->down;
        };
        $r = $f->wait_reason;
        is $r->[0], 'Semaphore down', 'reason names the semaphore wait';
        is $r->[1], __FILE__,         'file is the down() caller';
        is $r->[2], $line,            'line is the down() call site';
        $sem->up;
        $f->await;
        ok !defined $f->wait_reason, 'reason is cleared once the fiber resumes';
    };
};
subtest 'signal wait records reason and caller location' => sub {
    my $sig = Acme::Parataxis::Signal->new( count => false );
    my ( $r, $line );
    async {
        my $f = fiber {
            $line = __LINE__ + 1;
            $sig->wait;
        };
        $r = $f->wait_reason;
        is $r->[0], 'Signal wait', 'reason names the signal wait';
        is $r->[1], __FILE__,      'file is the wait() caller';
        is $r->[2], $line,         'line is the wait() call site';
        $sig->send;
        $f->await;
    };
};
subtest 'future await records reason and caller location' => sub {
    my $fut = Acme::Parataxis::Future->new;
    my ( $r, $line, $v );
    async {
        my $f = fiber {
            $line = __LINE__ + 1;
            $v    = $fut->await;
        };
        $r = $f->wait_reason;
        is $r->[0], 'Future await', 'reason names the future await';
        is $r->[1], __FILE__,       'file is the await() caller';
        is $r->[2], $line,          'line is the await() call site';
        $fut->set_result('ok');
        $f->await;
        is $v, 'ok', 'awaited value delivered';
    };
};
subtest 'fiber await records reason and caller location' => sub {
    my $child = fiber { await_sleep(30); return 'kid' };
    my ( $r, $line );
    async {
        my $f = fiber {
            $line = __LINE__ + 1;
            $child->await;
        };
        $r = $f->wait_reason;
        is $r->[0],   'fiber await', 'reason names the fiber await';
        is $r->[1],   __FILE__,      'file is the child await caller';
        is $r->[2],   $line,         'line is the child await call site';
        is $f->await, 'kid',         'child result delivered';
    };
};
subtest 'channel get/put record distinct reasons' => sub {
    my $ch = Acme::Parataxis::Channel->new( capacity => 1 );
    my ( $rg, $lg );
    async {
        my $g = fiber {
            $lg = __LINE__ + 1;
            $ch->get;
        };
        $rg = $g->wait_reason;
        is $rg->[0], 'Channel get', 'getter park record';
        is $rg->[1], __FILE__,      'getter file';
        is $rg->[2], $lg,           'getter line';
        $ch->put('x');    # wakes the parked getter through the get semaphore
        $g->await;
        $ch->put('y');    # buffer full again: putters must park
        my ( $rp, $lp );
        my $p = fiber {
            $lp = __LINE__ + 1;
            $ch->put('z');
        };
        $rp = $p->wait_reason;
        is $rp->[0], 'Channel put', 'putter park record';
        is $rp->[1], __FILE__,      'putter file';
        is $rp->[2], $lp,           'putter line';
        my $v = fiber { $ch->get };    # drains 'y', making room for the putter
        $v->await;
        $p->await;
    };
};
subtest 'fiber wait (busy spin for a child) records a reason' => sub {
    my ( $r, $line );
    async {
        my $child = fiber { await_sleep(30); return 'kid' };
        my $w     = fiber {
            $line = __LINE__ + 1;
            $child->wait;
        };
        yield for 1 .. 2;
        $r = $w->wait_reason;
        is $r->[0],   'fiber wait', 'busy child wait records a reason';
        is $r->[1],   __FILE__,     'file is the wait() caller';
        is $r->[2],   $line,        'line is the wait() call site';
        is $w->await, 'kid',        'result delivered after the spin';
        ok !defined $w->wait_reason, 'reason cleared when the wait returns';
    };
};
subtest 'on_wake fires in order, before the fiber resumes' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my @order;
    async {
        my $f = fiber {
            on_wake( sub ($fiber) { push @order, 'hook1' } );
            Acme::Parataxis->on_wake( sub ($fiber) { push @order, 'hook2' } );
            $sem->down;
            push @order, 'body';
        };
        yield for 1 .. 2;
        is join( q{}, @order ), '', 'hooks quiet while parked';
        $sem->up;
        $f->await;
        is join( q{}, @order ), 'hook1hook2body', 'hooks fire in order, before the body resumes';
    };
};
subtest 'on_wake fires once per registration' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my $n   = 0;
    async {
        my $f = fiber {
            on_wake( sub ($fiber) { $n++ } );
            $sem->down;    # first park: hook fires on the resume
            $sem->down;    # second park: no hook registered
        };
        $sem->up for 1 .. 2;
        yield for 1 .. 5;
        $f->await;
    };
    is $n, 1, 'hook fires only for the park it was registered for';
};
subtest 'on_wake validation' => sub {
    like dies {
        on_wake( sub { } )
    }, qr[scheduled fiber], 'outside a fiber it croaks';
    async {
        my $f = fiber {
            like dies { on_wake(42) }, qr[CODE ref], 'a non-code arg croaks';
        };
        $f->await;
    };
};
#
done_testing;
