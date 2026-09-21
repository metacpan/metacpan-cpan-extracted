use v5.40;
use blib;
use Acme::Parataxis::Future;
use Acme::Parataxis qw[async fiber await yield await_sleep];
use Test2::V1 -ipP;
$|++;
#
subtest 'construction: a new future is not ready and has no result' => sub {
    my $f = Acme::Parataxis::Future->new;
    ok !$f->is_ready, 'not ready on construction';
    like dies { $f->result }, qr[not ready], 'result() croaks before the future is ready';
};
subtest 'set_result: marks the future ready and stores the value' => sub {
    for my $val ( 0, '', undef, 'x', 42 ) {
        my $f = Acme::Parataxis::Future->new;
        $f->set_result($val);
        ok $f->is_ready, 'ready after set_result';
        is $f->result, $val, 'result() returns the stored value';
    }
};
subtest 'resolving twice dies' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result(1);
    ok dies { $f->set_result(2) }, 'second set_result dies';
    my $g = Acme::Parataxis::Future->new;
    $g->set_error('e');
    ok dies { $g->set_result('late'); 1 }, 'set_result after set_error dies';
    ok dies { $g->set_error('again'); },   'second set_error dies';
};
subtest 'set_error: marks the future ready and is visible to result()' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_error('kaput');
    ok $f->is_ready, 'ready after set_error';
    like dies { $f->result; 1 }, qr[kaput], 'result() dies on an errored future';
};
subtest 'on_ready: fires in registration order with the future as argument' => sub {
    my $f = Acme::Parataxis::Future->new;
    my @seen;
    $f->on_ready( sub ($future) { push @seen, 'a:' . $future->result } );
    $f->on_ready( sub ($future) { push @seen, 'b:' . $future->result } );
    $f->set_result('x');
    is join( ' ', @seen ), 'a:x b:x', 'callbacks run in order with the future';
};
subtest 'on_ready: fires immediately when the future is already ready' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result('v');
    my @seen;
    $f->on_ready( sub ($future) { push @seen, $future->result } );
    is join( '', @seen ), 'v', 'callback ran synchronously';
};
subtest 'await: blocks a fiber until a producer resolves the future' => sub {
    my $f   = Acme::Parataxis::Future->new;
    my $got = 'sentinel';
    async {
        fiber {
            yield;
            $f->set_result('done');
        };
        $got = $f->await;
    };
    is $got, 'done', 'awaiter resumed with the producer result';
};
subtest 'await: returns immediately when the future is already ready' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result('instant');
    is $f->await, 'instant', 'await on a ready future needs no fiber';
};
subtest 'await: dies with the stored error' => sub {
    my $f = Acme::Parataxis::Future->new;
    my $err;
    async {
        fiber {
            yield;
            $f->set_error('ouch');
        };
        eval { $f->await; 1 };
        $err = $@;
    };
    like $err, qr[ouch], 'awaiter dies with the producer error';
};
subtest 'await: multiple fibers may await the same future' => sub {
    my $f = Acme::Parataxis::Future->new;
    my ( @waiters, @got );
    async {
        @waiters = map {
            my $w = $_;
            fiber { push @got, $f->await; $w }
        } qw[A B C];
        await_sleep(10);    # let each waiter suspend on the future
        $f->set_result('ready');
    };
    my %res = map { $_->await => 1 } @waiters;
    is \%res, { A => T(), B => T(), C => T() }, 'every waiter was resumed';
    is \@got, [ 'ready', 'ready', 'ready' ], 'all observed the same result';
};
subtest 'clear_result: resets the future for reuse' => sub {
    my $f     = Acme::Parataxis::Future->new;
    my $fired = 0;
    $f->on_ready( sub ($future) { $fired++ } );
    $f->set_result('first');
    is $fired, 1, 'callback fired on the first set';
    ok $f->is_ready, 'ready after the first set';
    $f->clear_result;
    is $f->is_ready, F(), 'not ready after clear_result';
    ok dies { $f->result; 1 }, 'result() croaks on a cleared future';
    $f->set_result('second');
    is $f->result, 'second', 'future is reusable after clear_result';
    is $fired,     1,        'stale callbacks do not fire again after clear_result';
};
subtest 'clear_result: a recycled future may be awaited again' => sub {
    my $f = Acme::Parataxis::Future->new;
    my $got;
    async {
        fiber { yield; $f->set_result('one') };
        $got = $f->await;
    };
    is $got, 'one', 'first await ok';
    $f->clear_result;
    is $f->is_ready, F(), 'recycled future is not ready';
    async {
        fiber { yield; $f->set_result('two') };
        $got = $f->await;
    };
    is $got, 'two', 'recycled future awaited again';
};
subtest 'await: an unready future cannot be awaited from the mainline' => sub {
    my $f = Acme::Parataxis::Future->new;
    like dies { $f->await }, qr[scheduled fiber], 'mainline await on an unready future croaks';
};
#
done_testing();
