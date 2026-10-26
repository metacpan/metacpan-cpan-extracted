use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await_sleep with_timeout];
use Acme::Parataxis::Sync::Barrier;
use Test2::V1 -ipP;
$|++;
subtest 'every party is released exactly once per phase, in lockstep' => sub {
    my $b = Acme::Parataxis::Sync::Barrier->new( parties => 3 );
    my @crossed;
    async {
        my @fs = map {
            my $i = $_;
            fiber {
                for my $phase ( 1 .. 2 ) {
                    $b->arrive_and_wait;
                    push @crossed, $i;
                }
            }
        } 1 .. 3;
        $_->await for @fs;
    };
    is scalar @crossed, 6, 'three parties crossed two phases';
    for my $phase ( 1 .. 2 ) {
        my $lo     = $phase == 1 ? 0 : 3;
        my @sorted = sort @crossed[ $lo .. $lo + 2 ];
        is join( ',', @sorted ), '1,2,3', "phase $phase released each party exactly once";
    }
};
subtest 'releases exactly n even when a party parks longer' => sub {
    my $b = Acme::Parataxis::Sync::Barrier->new( parties => 3 );
    my @crossed;
    async {
        my %fs = map {
            my $i = $_;
            $i => fiber {
                my $delay = $i == 2 ? 8 : 0;

                # emit arrival tick, then (for party 2) park mid-phase before arriving
                my $arrived = fiber { await_sleep($delay); $b->arrive_and_wait; 1 };
                $arrived->await;
                push @crossed, $i;
            }
        } 1 .. 3;
        $_->await for @{ [ values %fs ] };
    };
    is join( ',', sort @crossed ), '1,2,3', 'the slow party did not hold anyone past the boundary';
};
subtest 'a barrier is reusable for fresh generations' => sub {
    my $b      = Acme::Parataxis::Sync::Barrier->new( parties => 2 );
    my $rounds = 0;
    async {
        for my $round ( 1 .. 3 ) {
            my @fs = map {
                fiber {
                    $b->arrive_and_wait;
                    $rounds++;
                }
            } 1 .. 2;
            $_->await for @fs;
        }
    };
    is $rounds, 6, 'two parties completed three consecutive generations';
};
subtest 'an interrupted arrival unregisters without blocking the phase' => sub {
    my $b = Acme::Parataxis::Sync::Barrier->new( parties => 3 );
    my $err;
    async {
        $err = dies {
            with_timeout( 10, sub { $b->arrive_and_wait } );
        };
        is $b->waiters, 0, 'the timed-out arriver removed itself';

        # two arrivals are still booked for this phase; two live parties finish it
        my $two = fiber { $b->arrive_and_wait; 'two' };
        my $ret = $b->arrive_and_wait;
        is $ret,          1,     'the main arrival released the phase';
        is $two->await,   'two', 'the other live party was released too';
        is $b->remaining, 3,     'a fresh phase is armed for the next generation';
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the first arrival timed out';
};
subtest 'barrier construction and waits outside the scheduler croak' => sub {
    like dies { Acme::Parataxis::Sync::Barrier->new( parties => 0 ) }, qr/positive number of parties/, 'parties < 1 croaks at construction';
    my $b = Acme::Parataxis::Sync::Barrier->new( parties => 2 );
    like dies { $b->arrive_and_wait }, qr/scheduled fiber/, 'arrive_and_wait croaks outside the scheduler';
};
#
done_testing;
