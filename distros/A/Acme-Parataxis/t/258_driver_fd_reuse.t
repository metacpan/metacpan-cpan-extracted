use v5.40;
use experimental qw[class];
use blib;
use Test2::V1 -ipP;
use Acme::Parataxis::Driver;
use Acme::Parataxis::Driver::Mojo;
use Acme::Parataxis::Driver::IOAsync;
#
# The drivers key their watch tables by descriptor number, and a number is not an identity: the OS recycles it the
# instant a handle is closed. A handle that is watched and then closed without unwatching leaves its slot behind, and
# the next handle to be given that number used to inherit it. The slot is what the driver consults before registering
# a handle with the underlying loop, so inheriting one meant the new handle was never registered at all -- and a fiber
# parked on it waits out its deadline for a readiness event nothing is going to deliver.
#
# That is the shape of the lost wakeup in t/256, reproduced here in miniature and on purpose. The failure is far too
# rare to catch by waiting for it, so this forces the collision: close a watched handle, then build pipes until the
# OS hands the freed number back. The first two assertions are red without the fix and green with it.
#
# Nothing here needs a fiber or a run loop. The defect is in the bookkeeping, so the bookkeeping is what is tested.
# A pipe whose read end carries exactly $fd, or an empty list if the OS will not co-operate within a bounded number
# of tries. A pipe is the cheapest watchable handle whose number returns to the free list on close.
sub pipe_on_fd ($fd) {
    for ( 1 .. 64 ) {
        pipe( my $r, my $w ) or die "pipe: $!";
        return ( $r, $w ) if fileno($r) == $fd;
        close $r;
        close $w;
    }
    return ();
}

# The collision: watch a handle, close it without unwatching, then reclaim its number for an unrelated handle.
# Returns ( $stale_fd, $recycled_read_end, $recycled_write_end ), or an empty list if the number stayed free.
sub make_collision ($driver) {
    pipe( my $a_r, my $a_w ) or die "pipe: $!";
    my $fd = fileno($a_r);
    $driver->watch_read( $a_r, sub { } );
    close $a_r;    # closed while still watched: the slot outlives the handle
    close $a_w;
    my @b = pipe_on_fd($fd);
    return () if !@b;
    return ( $fd, @b );
}

# Each driver gets the same battery. A driver whose loop is not installed is skipped rather than failed, matching
# t/256 and t/257, so this file is not a reason for the suite to go red on a box without Mojo or IO::Async.
sub exercise ( $name, $build, $reusable ) {

    # 1. A recycled number must not report as watched. This is the false positive that silently skipped registering
    #    the new handle with the loop: has_watch() answered for the dead handle's slot because the number matched.
    my $driver = $build->();
    my ( $fd, $b, $bw ) = make_collision($driver);
    if ( !defined $fd ) {
        note("the OS did not recycle the descriptor within 64 pipes ($name), so there is nothing to assert here");
        return;
    }
    ok( !$driver->has_watch($b), "$name: a recycled descriptor is not a live watch" );

    # 2. Unwatching a handle that was never watched must not take down the stranger's slot. Before the fix this
    #    returned 1 and deleted that slot, so a third handle could then be registered against an entry nobody owned.
    is( $driver->unwatch($b), 0, "$name: unwatch on a never-watched handle is refused" );

    # 3. Claiming the number for real, and having the loop take it. This step is only meaningful for Mojo, and the
    #    reason is worth recording because it is not a Parataxis choice. Mojo keys its watcher table by descriptor
    #    number, so handing it a recycled number replaces the entry and it recovers by itself. IO::Async's Epoll
    #    backend keys the same table by descriptor but *also* remembers which handle it registered there: a re-watch
    #    with an unchanged mask falls through every branch and is dropped without a word, and the later unwatch finds
    #    a handle identity it no longer agrees with and croaks. It cannot be told to forget the old handle either,
    #    because that handle is closed and there is no descriptor left to look it up by. So on IO::Async nothing
    #    Parataxis does can be observed end to end here, and asserting it would either pass vacuously or report a
    #    red test for somebody else's bug. What Parataxis does own -- the two assertions above -- is asserted for both.
    if ($reusable) {
        my $registered = eval {
            $driver->watch_read( $b, sub { } );
            1;
        };
        if ( !$registered ) {
            my $err = $@;
            chomp $err;
            diag("$name: the loop refused the recycled descriptor outright: $err");
            skip( "$name: the loop cannot be handed a recycled descriptor it still holds under", 1 );
        }
        else {
            ok( $driver->has_watch($b), "$name: the new handle is watched once asked" );
            is( $driver->watch_count, 1, "$name: exactly one slot is held for it" );
        }
    }
    else {
        note( "$name: the loop has no end-to-end behaviour for a recycled descriptor to assert against, " .
                'so the two loop-facing assertions below are made for Mojo only' );
    }
    $driver->reset;
    close $b;

    # 4. A fresh slot must not inherit the previous owner's direction. Watching write-only, closing, then watching
    #    the recycled number read-only used to leave the dead write callback in place, so the reactor polled for
    #    writability the new handle never asked for and would fire a closure whose fiber is long gone. This asks the
    #    Mojo reactor directly because that is where the mask lives; the bit is only read, never set.
    if ( $name eq 'Mojo' ) {
        my $loop = Mojo::IOLoop->new;
        my $drv2 = Acme::Parataxis::Driver::Mojo->new( loop => $loop );
        pipe( my $w_r, my $w_w ) or die "pipe: $!";
        my $wfd = fileno($w_w);
        $drv2->watch_write( $w_w, sub { } );
        close $w_w;
        my @r = pipe_on_fd($wfd);
        if (@r) {
            my ($r2) = @r;
            $drv2->watch_read( $r2, sub { } );
            my $mode = $loop->reactor->{io}{$wfd}{mode} // 0;
            ok( !( $mode & 4 ), "Mojo: the recycled slot carries no stale writable interest (mode $mode)" );
        }
        else { note('the OS did not recycle the descriptor, so the mask cannot be read') }
        $drv2->reset;
    }

    # 5. A slot whose handle was closed while watched must not survive reset(). It cannot be reached by number any
    #    more, so the walk over the table misses it, and pending() stays true forever -- which tells the scheduler's
    #    idle branch that the loop has work when it does not, run after run. This is the base class's own table and
    #    does not depend on the loop at all, so a loop that refuses to unwind is reported but not allowed to stand in
    #    the way of the assertion.
    my $drv3 = $build->();
    my ( $d3, $c, $cw ) = make_collision($drv3);
    if ( defined $d3 ) {
        my $unwound = eval { $drv3->reset; 1 };
        if ( !$unwound ) {
            my $err = $@;
            chomp $err;
            diag("$name: the loop refused to unwind a handle that was closed under it: $err");
        }
        is( $drv3->pending, 0, "$name: reset clears a slot left by a handle closed while watched" );
    }
    else { note('the OS did not recycle the descriptor, so there is no stale slot to reset') }
}
subtest 'Driver::Mojo' => sub {
    plan skip_all => 'Mojo::IOLoop not installed' unless eval { require Mojo::IOLoop; 1 };
    exercise( 'Mojo', sub { Acme::Parataxis::Driver::Mojo->new( loop => Mojo::IOLoop->new ) }, 1 );
};
subtest 'Driver::IOAsync' => sub {
    plan skip_all => 'IO::Async::Loop not installed' unless eval { require IO::Async::Loop; 1 };
    exercise( 'IOAsync', sub { Acme::Parataxis::Driver::IOAsync->new( loop => IO::Async::Loop->new ) }, 0 );
};
done_testing;
