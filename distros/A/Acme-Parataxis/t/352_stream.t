use v5.40;
use blib;
use Time::HiRes     qw[time];
use Acme::Parataxis qw[async fiber yield await_sleep];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Stream;
use Test2::V1 -ipP;
$|++;
sub now_ms { time() * 1000 }

# How many live fibers name a parked Channel put (the backpressure bullet).
sub parked_puts () {
    my $f = Acme::Parataxis::dump_fibers();
    my $n = 0;
    for my $row (@$f) {
        my $reason = $row->{reason};
        $n++ if $reason && $reason->[0] eq 'Channel put';
    }
    return $n;
}

# Polls until every fiber of the chain is gone, so the leak assertions never race the unwinding. The baseline is
# taken OUTSIDE the async body, which is itself a live fiber, so the count can only fall to baseline + 1 in here.
sub drain_chain ($baseline) {
    my $target = $baseline + 1;
    my $t      = 0;
    while ( Acme::Parataxis::get_live_fiber_count() > $target && $t++ < 10000 ) { await_sleep 1 }
}
subtest 'map/filter/batch produce only transformed/filtered/grouped items, in order' => sub {
    my $baseline = Acme::Parataxis::get_live_fiber_count();
    my @batches;
    async {
        my $raw = Acme::Parataxis::Channel->new( capacity => 16 );
        my $chain
            = Acme::Parataxis::Stream->from_channel($raw)
            ->map( sub ($e) { $e * 100 } )
            ->filter( sub ($e) { $e >= 300 } )
            ->batch(2)
            ->consume( sub (@g) { push @batches, [@g] } );
        $raw->put($_) for 1 .. 6;
        $raw->shutdown;
        my $t = 0;
        while ( @batches < 2 && $t++ < 10000 ) { await_sleep 1 }
        drain_chain($baseline);
    };
    is \@batches,                               [ [ 300, 400 ], [ 500, 600 ] ], 'map applied, filter dropped 100/200, batch grouped in order';
    is Acme::Parataxis::get_live_fiber_count(), $baseline,                      'the whole chain ended and left zero leaked fibers';
};
subtest 'backpressure: a slow consume parks the upstream producer on the full bounded channel' => sub {
    my $baseline = Acme::Parataxis::get_live_fiber_count();
    my ( $saw, $busy );
    async {
        my $raw = Acme::Parataxis::Channel->new( capacity => 4 );
        my $chain
            = Acme::Parataxis::Stream->from_channel( $raw, stage_capacity => 4 )
            ->map( sub ($x) { $x + 1 } )
            ->consume( sub ($x) { $saw = $x; yield while $busy } );

        # Fill the 4-slot pipeline, then make the consumer the bottleneck.
        $busy = 1;
        fiber { $raw->put($_) for 1 .. 20; 1 };
        my $t = 0;
        while ( parked_puts() < 1 && $t++ < 10000 ) { await_sleep 1 }
        ok parked_puts() >= 1, 'the producer parked upstream on a full bounded channel (backpressure is real)';

        # Let the consumer drain the whole 20-item stream, then close the source and let the chain unwind.
        $busy = 0;
        $t    = 0;
        while ( parked_puts() > 0 && $t++ < 10000 ) { await_sleep 1 }
        $raw->shutdown;
        drain_chain($baseline);
    };
    is Acme::Parataxis::get_live_fiber_count(), $baseline, 'after shutdown the parked producer woke and exited; zero leaked fibers';
    ok defined $saw, 'and the slow consumer still received at least one item';
};
subtest 'throttle caps the emission rate' => sub {
    my $baseline = Acme::Parataxis::get_live_fiber_count();
    my @at;
    async {
        my $raw   = Acme::Parataxis::Channel->new( capacity => 32 );
        my $chain = Acme::Parataxis::Stream->from_channel($raw)->throttle(100)    # at most 100/s => >= 10ms between emissions
            ->consume( sub ($x) { push @at, now_ms } );
        $raw->put($_) for 1 .. 5;
        my $t = now_ms;
        while ( @at < 5 && now_ms -$t < 2000 ) { await_sleep 1 }
        $raw->shutdown;
        drain_chain($baseline);
    };
    my $span = ( $at[-1] - $at[0] ) / 1000;
    ok $span >= 0.030, 'five throttled emissions did not all land in the same millisecond (rate capped)';
    is Acme::Parataxis::get_live_fiber_count(), $baseline, 'throttle released its fiber on shutdown; zero leaked';
};
subtest 'batch_time takes its deadline from the ms argument, not from the first item' => sub {
    my $baseline = Acme::Parataxis::get_live_fiber_count();
    my ( @groups, $early );
    async {
        my $raw   = Acme::Parataxis::Channel->new( capacity => 32 );
        my $chain = Acme::Parataxis::Stream->from_channel($raw)->batch_time(200)    # a window a short sleep cannot cross
            ->consume( sub (@g) { push @groups, [@g] } );
        $raw->put('alpha');    # a NON-numeric item: the old code did `$deadline = now_ms() + $item`
        await_sleep 10;        # well inside the 200ms window
        $early = scalar @groups;
        $raw->shutdown;
        while ( @groups < 1 ) { await_sleep 1 }
        drain_chain($baseline);
    };
    is $early,   0,                                        'the batch was still pending 10ms in, so the deadline came from 200ms, not from the item';
    is \@groups, [ ['alpha'] ],                            'and the deadline flushed exactly the one item, undamaged';
    is Acme::Parataxis::get_live_fiber_count(), $baseline, 'batch_time released its fiber on shutdown; zero leaked';
};
subtest 'batch_time groups on the deadline' => sub {
    my $baseline = Acme::Parataxis::get_live_fiber_count();
    my @groups;
    async {
        my $raw   = Acme::Parataxis::Channel->new( capacity => 32 );
        my $chain = Acme::Parataxis::Stream->from_channel($raw)->batch_time(50)    # flush every 50ms
            ->consume( sub (@g) { push @groups, [@g] } );
        $raw->put(1);                                                              # one item, then let the deadline fire on its own
        my $t = 0;
        while ( @groups < 1 && $t++ < 10000 ) { await_sleep 1 }
        $raw->put($_) for 2, 3;
        my $u = 0;
        while ( @groups < 2 && $u++ < 10000 ) { await_sleep 1 }
        $raw->shutdown;                                                            # teardown flush delivers the tail batch
        drain_chain($baseline);
    };
    is \@groups,                                [ [1], [ 2, 3 ] ], 'the deadline flushed the lone item; shutdown flushed 2 and 3 as one batch';
    is Acme::Parataxis::get_live_fiber_count(), $baseline,         'batch_time released its fiber on shutdown; zero leaked';
};
done_testing;
