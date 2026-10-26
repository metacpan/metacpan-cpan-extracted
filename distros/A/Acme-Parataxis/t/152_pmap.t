use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield pmap await_sleep];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Future;
use Test2::V1 -ipP;
$|++;

# Each mapper parks on its own per-item sync object (a single waiter per object) and every producer releases its gates
# one at a time, interleaving yields between releases. Batch-releasing many gates at once (a producer that parks for a
# while and then floods the objects) leaves the shared CvDEPTH bookkeeping on the mapper sub pinned past the END
# cleanup, so Perl's teardown emits "Can't undef active subroutine during global destruction." Interleaving every
# release keeps that bookkeeping symmetrical and the teardown quiet.
subtest 'results come back in input order even when items finish out of order' => sub {
    async {
        my @in    = 1 .. 8;
        my @gates = map { Acme::Parataxis::Channel->new } @in;
        fiber {
            for my $i ( reverse @in ) {
                yield for 1 .. 3;    # release each item's gate one at a time
                $gates[ $i - 1 ]->put(1);
            }
        };
        my @out = pmap(
            { concurrency => 3 },
            sub ($x) {
                $gates[ $x - 1 ]->get;    # parks until its own gate is released
                return $x * 10;
            },
            @in
        );
        is \@out, [ map { $_ * 10 } 1 .. 8 ], 'input order preserved under out-of-order completion';
    };
};
subtest 'the concurrency cap is honored' => sub {
    async {
        my $in_flight = 0;
        my $max       = 0;
        my @gates     = map { Acme::Parataxis::Channel->new } 1 .. 16;
        fiber {
            for my $i ( reverse 1 .. 16 ) {
                yield for 1 .. 3;    # release one gate per step, so every worker parks first
                $gates[ $i - 1 ]->put(1);
            }
        };
        pmap(
            { concurrency => 4 },
            sub ($x) {
                $in_flight++;
                $max = $in_flight if $in_flight > $max;
                $gates[ $x - 1 ]->get;
                $in_flight--;
                return $x;
            },
            1 .. 16
        );
        is $max,       4, 'at most 4 mappers ran at once';
        is $in_flight, 0, 'all workers drained before pmap returned';
    };
};
subtest 'mapper code may await a future and park' => sub {
    async {
        my %f = map { $_ => Acme::Parataxis::Future->new } qw[a b];
        fiber {
            for my $k ( reverse qw[a b] ) {
                yield for 1 .. 3;    # resolve one future per step
                $f{$k}->set_result('!');
            }
        };
        my @out = pmap( sub ($x) { $x . $f{$x}->await }, 'a', 'b' );
        is \@out, [ 'a!', 'b!' ], 'each mapper awaited its future';
    };
};
subtest 'mapper code may park on a channel' => sub {
    async {
        my %chs = map { $_ => Acme::Parataxis::Channel->new } qw[a b];
        fiber {
            for my $k ( reverse qw[a b] ) {
                yield for 1 .. 3;    # seed one channel per step
                $chs{$k}->put('sauce');
            }
        };
        my @out = pmap( sub ($x) { $x . $chs{$x}->get }, 'a', 'b' );
        is \@out, [ 'asauce', 'bsauce' ], 'workers pulled from their channels in order';
    };
};
subtest 'a mapper death cancels the pool and is rethrown' => sub {
    my @attempted;
    my $err;
    async {
        $err = dies {
            pmap(
                { concurrency => 3 },
                sub ($x) {
                    push @attempted, $x;
                    die "map-fail-$x" if $x == 2;
                    await_sleep(2);
                    return $x;
                },
                1 .. 9
            );
            1;
        };
    };
    like $err, qr/map-fail-2/, 'the first failure was rethrown';
    ok !grep( { $_ > 2 } @attempted ), 'nothing past the failing item was mapped (the pool cancelled)';
};
subtest 'an empty item list returns immediately with ()' => sub {
    async {
        my @out = pmap( sub { die 'never called' }, () );
        is \@out, [], 'no mapper ran on an empty list';
    };
};
subtest 'pmap must run inside a scheduled fiber' => sub {
    like dies {
        pmap( sub {1}, 1 .. 3 )
    }, qr/scheduled fiber/, 'mainline pmap croaks';
};
subtest 'concurrency must be a positive integer' => sub {
    async {
        like dies {
            pmap( { concurrency => 0 }, sub {1}, 1 .. 3 )
        }, qr/concurrency/, 'zero croaks';
        like dies {
            pmap( { concurrency => 'many' }, sub {1}, 1 .. 3 )
        }, qr/concurrency/, 'a word croaks';
        like dies {
            pmap( { concurrency => 2.5 }, sub {1}, 1 .. 3 )
        }, qr/concurrency/, 'a fraction croaks';
    };
};
subtest 'pmap is class-callable and defaults to one fiber per item' => sub {
    async {
        my @out = Acme::Parataxis->pmap( sub ($x) { $x * 2 }, 1 .. 4 );
        is \@out, [ 2, 4, 6, 8 ], 'class-callable with the default concurrency';
    };
};
subtest 'pmap returns an arrayref in scalar context' => sub {
    async {
        my $out = pmap( sub ($x) { $x + 1 }, 1, 2 );
        is $out, [ 2, 3 ], 'scalar context yields the results arrayref';
    };
};
#
done_testing();
