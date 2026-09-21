use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Semaphore;
use Test2::V1 -ipP;
$|++;
#
sub wait_for_drain { yield while Acme::Parataxis::get_live_fiber_count() > 1 }
subtest 'Single producer, single consumer (capacity 1, rendezvous)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 1 );
    my @got;
    async {
        fiber { $q->put($_) for 1 .. 9 };    # producer
        push @got, $q->get for 1 .. 9;       # consumer
    };
    is join( q{,}, @got ), '1,2,3,4,5,6,7,8,9', 'items arrive in order';
    is $q->size,           0,                   'channel fully drained';
};
subtest 'Capacity limit blocks the producer' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 3 );
    my @got;
    my $producer_done = 0;
    async {
        my $p = fiber { $q->put($_) for 1 .. 10; $producer_done = 1 };
        is $producer_done, F(), 'producer blocked on a full channel before the consumer ran';
        push @got, $q->get for 1 .. 10;
    };
    ok $producer_done, 'producer finished once the consumer drained the channel';
    is join( q{,}, @got ), '1,2,3,4,5,6,7,8,9,10', 'all items delivered';
};
subtest 'Multiple producers, one consumer (like eg/prodcons)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 4 );
    my @got;
    async {
        fiber { $q->put("p1-$_") for 1 .. 5 };
        fiber { $q->put("p2-$_") for 1 .. 5 };
        push @got, $q->get for 1 .. 10;
    };
    is scalar @got,             10,                                                  'consumer received everything';
    is join( q{,}, sort @got ), 'p1-1,p1-2,p1-3,p1-4,p1-5,p2-1,p2-2,p2-3,p2-4,p2-5', 'all messages present, none lost or duplicated';
};
subtest 'Shutdown wakes blocked consumers' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 2 );
    $q->put(1);
    my @got;
    async {
        fiber {
            while ( defined( my $x = $q->get ) ) {
                push @got, $x;
            }
        };
        $q->shutdown;
        yield for 1 .. 10;
        is join( q{,}, @got ), '1', 'buffered item consumed, then EOF signalled';
    };
};
subtest 'Prodcons stress (4 producers x 500, 4 consumers x 500, cap 2)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 2 );
    my @got;
    async {
        fiber { $q->put("$_") for 1 .. 500 };
        fiber { $q->put("$_") for 501 .. 1000 };
        fiber { $q->put("$_") for 1001 .. 1500 };
        fiber { $q->put("$_") for 1501 .. 2000 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        wait_for_drain();
    };
    is scalar @got,                           2000,                    'all items consumed';
    is join( q{,}, sort { $a <=> $b } @got ), join( q{,}, 1 .. 2000 ), 'no items lost or duplicated';
};
#
done_testing();
