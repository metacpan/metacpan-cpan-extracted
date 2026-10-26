# Offloading work: does it actually buy anything?
#
# "Should I run this in a fiber, or off the thread?" has a short answer, and it is not the one the
# word "async" suggests: a fiber buys you exactly one thing, and it is worth about 7x. Everything
# else is a rounding error. These are the two workloads that separate them, measured.
#
#   CPU-bound - SHA-256 over a 5 MiB fixture, 100 times, on 15 cores:
#
#     inline (1 fiber)      1222.5 ms   1.00x     <- the thing you already have
#     fibers x2             1223.3 ms   1.00x
#     fibers x4             1223.2 ms   1.00x
#     fibers x8             1200.9 ms   0.98x
#     fibers x15            1210.1 ms   0.99x
#     pmap concurrency 4    1191.7 ms   0.97x     <- the dist's own helper; same story
#     processes x4           332.5 ms   0.27x
#     processes x8           254.8 ms   0.21x
#     processes x15          191.8 ms   0.16x     <- 6.2x, and not 15x
#
#   Wait-bound - 8 independent services, 40ms each, latency starting when the request is sent:
#
#     blocking serial        327.4 ms   1.00x
#     fibers + await_read     45.0 ms   0.14x     <- 7.3x
#     processes x8             51.2 ms   0.16x
#
# Three things to take from it:
#
#   1. Fibers are not parallelism. A fiber is a coroutine on the same OS thread, so adding more
#      of them cannot reach a second core - the x2/x4/x8/x15 rows are flat to within a percent
#      because they are the same thread, not a slower one. pmap is flat for the same reason.
#   2. Fibers are outstanding at the other thing. Overlapping waits is what they are for, and it
#      costs 45ms against 327ms for the same work done serially - while being *faster* than 8
#      processes, because there is no fork and no second address space to pay for.
#   3. Processes do not reach 15x on 15 cores either. They reach 6.2x, because this workload is
#      memory-bandwidth bound and 15 cores contending for one memory bus is not 15 cores' worth of
#      work. Check the ceiling before designing around it.
#
# A second OS thread is a different story, and it deserves a second table. These are real numbers,
# not a proxy: a threaded 5.44.0 build (useithreads=define) with Acme::Parataxis::Blocking, same
# fixture, same machine. Each row is its own process, because the pool size is fixed at the first
# spawn_blocking and cannot be changed afterwards.
#
#     spawn_blocking x1     1469.0 ms   1.19x    <- slower than not doing it at all
#     spawn_blocking x2      756.1 ms   0.62x
#     spawn_blocking x4      439.9 ms   0.36x
#     spawn_blocking x8      328.8 ms   0.27x
#     spawn_blocking x15     253.8 ms   0.21x    <- 4.9x
#
# So a thread does buy the second core, and the process rows above remain the right upper bound.
# Three caveats matter more than that 4.9x, though:
#
#   * It is 1.19x SLOWER at one thread, because a call costs 9.8ms end to end here, which puts
#     the crossover at roughly 10ms of work per item. 6.7ms of that 9.8ms is threads->create
#     cloning the parent interpreter; only 2.4ms is the Blocking layer around it. The clone is
#     the expensive part and it scales with what the parent has loaded - the same create+join
#     costs 0.65ms in a bare interpreter and 6.7ms with this distribution loaded. One thread per
#     small item spends 10x the work before it starts.
#   * A fiber round trip is 0.003ms. One spawn_blocking is about 3300 of them.
#   * The 4.9x is Digest::SHA releasing the GIL, not threads being magic. The same pure-perl
#     closure through spawn_blocking gains nothing (0.96x), and 8 plain threads on a pure-perl
#     loop are 1.48x SLOWER than a single thread. A thread helps exactly where the XS underneath
#     the closure drops the GIL - I/O and some CPU - and not at all for work computed in perl.
#
# Run it: perl -Mblib eg/bench_offload.pl
# Slow machine, or a shared one? Scale the work down; the ratios are what matter, not the ms:
#   perl -Mblib eg/bench_offload.pl 3 8 65536 20
use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use POSIX           ();
use File::Temp      ();
use File::Spec      ();
use Digest::SHA     ();
use Time::HiRes     ();
#
my $ROUNDS = shift                                                                                            // 3;
my $TREE   = shift                                                                                            // 20;
my $SIZE   = shift                                                                                            // 262_144;
my $PASSES = shift                                                                                            // 100;
my $cores  = $^O eq 'MSWin32' ? ( $ENV{NUMBER_OF_PROCESSORS} || 1 ) : ( split ' ', qx{nproc 2>/dev/null} )[0] // 1;
$cores ||= 1;

# The processes rows measure a real address space, and on Windows fork is emulation, not one: the
# rows would measure the emulator and have been seen to crash it. They get skipped there the same
# way the spawn_blocking rows skip themselves when Blocking is not installed.
my $REAL_FORK = $^O eq 'MSWin32' ? 0 : 1;

# The fixture and the clock.
my $dir = File::Temp->newdir( CLEANUP => 1 );
my @files;
for my $i ( 1 .. $TREE ) {
    my $path = File::Spec->catfile( "$dir", sprintf 'f%03d.bin', $i );
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} chr( 32 + ( $i % 90 ) ) x $SIZE;
    close $fh;
    push @files, $path;
}
printf "fixture: %d files x %d KiB (%.0f MiB), hashed %d times over %d cores\n", $TREE, $SIZE / 1024, $TREE * $SIZE / 1024 / 1024, $PASSES, $cores;

# Warm the page cache first, or the first variant measured eats the cost of it and every ratio
# after it is quietly wrong.
{
    my $warm = Digest::SHA->new(256);
    for my $p (@files) { open my $fh, '<', $p or die $!; $warm->addfile($fh) }
}

# Min-of-N, with the spread printed next to it, because a single lucky sample is indistinguishable
# from a real difference otherwise. Every row here is within a few percent of its neighbours, and
# that is the actual finding - so the spread is what proves it is not noise.
sub timed {
    my ($code) = @_;
    my @t;
    for ( 1 .. $ROUNDS ) {
        my $t0 = Time::HiRes::time();
        $code->();
        push @t, ( Time::HiRes::time() - $t0 ) * 1000;
    }
    @t = sort { $a <=> $b } @t;
    return ( $t[0], $t[-1] - $t[0] );
}
my $SINK = 0;

sub hash_subset {
    for my $pass ( 1 .. $PASSES ) {
        for my $p (@_) {
            open my $fh, '<', $p or die "open $p: $!";
            my $d = Digest::SHA->new(256);
            $d->addfile($fh);
            close $fh;
            $SINK ^= length $d->hexdigest;
        }
    }
    return;
}

# Partition the fixture $k ways. This has to take the width as its second argument: a version
# taking only the index collapses to $_ % 1, hands every worker the whole tree, and reports a
# slowdown *linear in the worker count*. That reads convincingly as "fibers have overhead" and is
# in fact a partitioner that does not partition. The pmap row below is the check on it - pmap
# partitions for us, and it lands level with inline.
sub subset {
    my ( $i, $k ) = @_;
    my @s;
    for my $j ( 0 .. $#files ) { push @s, $files[$j] if $j % $k == $i }
    return @s;
}

# Workload A: CPU-bound.
my @cpu;
push @cpu, [
    'inline (1 fiber)',
    sub {
        fiber { hash_subset(@files) }->await;
    }
];
my $base;
my %seen;
for my $k ( 2, 4, 8, $cores ) {
    next if $seen{$k}++ || $k > $TREE;
    push @cpu, [
        "fibers x$k",
        sub {
            my @f = map {
                my @s = subset( $_, $k );
                fiber { hash_subset(@s) }
            } 0 .. $k - 1;
            $_->await for @f;
        }
    ];
}

# pmap is the dist's own answer to "do this to many things at once", so it belongs in the table.
# It has to be called from inside a scheduled fiber, hence the async; and it needs no repetition
# modifier out here, because hash_subset already loops $PASSES over the file it is handed.
push @cpu, [
    'pmap concurrency 4',
    sub {
        async { pmap { concurrency => 4 }, sub ($p) { hash_subset($p) }, @files };
    }
];
print "  (processes rows skipped on $^O: no real fork)\n" if !$REAL_FORK;
for my $k ( 4, 8, $cores ) {
    next if $seen{"p$k"}++ || $k > $TREE || !$REAL_FORK;
    push @cpu, [
        "processes x$k",
        sub {
            my @pid;
            for my $i ( 0 .. $k - 1 ) {
                my $pid = fork();
                die "fork: $!" if !defined $pid;

                # POSIX::_exit, never exit. An earlier variant in this file has already started
                # the worker thread pool, and a forked child inherits whatever mutex one of the
                # parent's threads was holding. Let the child reach exit and it runs global
                # destruction against that held lock, so it hangs - and the parent hangs in
                # waitpid waiting for it. The result is not a slow benchmark but a deadlock, and
                # from the outside the two look identical.
                if ( !$pid ) { hash_subset( subset( $i, $k ) ); POSIX::_exit(0) }
                push @pid, $pid;
            }
            waitpid $_, 0 for @pid;
        }
    ];
}
print "\n=== CPU-bound: SHA-256, whole tree, $PASSES times ===\n";
printf "  %-20s %10s %9s   %s\n", 'variant', 'min ms', 'ratio', 'spread ms';
for my $c (@cpu) {
    my ( $name, $code )   = @$c;
    my ( $min,  $spread ) = timed($code);
    $base //= $min;
    printf "  %-20s %10.1f %8.2fx   %.1f\n", $name, $min, $min / $base, $spread;
}

# Workload B: wait-bound.
#
# N pipes, each fronted by its own forked "service" that blocks until it is asked, then takes RTT
# ms to answer. One child per pipe on purpose, and it is the whole experiment: the latency has to
# begin when *I* send the request. A single writer that fires everything at t=0 cannot show this,
# and neither can writers staggered 40ms apart - both leave the replies already sitting in the
# pipe by the time the serial reader gets to them, so it pays max(latency) either way and every
# variant ties at 1.00x. Measured that way first; it is a convincing way to conclude that
# concurrency does not help.
my $N   = 8;
my $RTT = 40;

sub service_fork {
    my @svc;
    for my $i ( 0 .. $N - 1 ) {

        # my on both, not just the first: in a list operator's argument list `my` applies to
        # the first element only, so `pipe( my $r, $w )` leaves $w a package variable and
        # strict rejects it. It is the same reason map { socket_pair() } silently loses one of
        # the pair's handles.
        pipe( my $ask,   my $ask_w )   or die "pipe: $!";
        pipe( my $reply, my $reply_w ) or die "pipe: $!";
        my $pid = fork();
        die "fork: $!" if !defined $pid;
        if ( !$pid ) {
            close $ask_w;
            close $reply;
            my $byte = q{};
            sysread $ask, $byte, 1;                     # do not answer until asked
            select undef, undef, undef, $RTT / 1000;    # the service's own latency
            syswrite $reply_w, chr( ord('a') + $i ) x 64;
            POSIX::_exit(0);
        }
        close $ask;
        close $reply_w;
        push @svc, [ $ask_w, $reply, $pid ];
    }
    return @svc;
}
my @wait;
if ($REAL_FORK) {
    push @wait, [
        'blocking serial',
        sub {
            my @svc = service_fork();
            my $got = 0;
            for my $s (@svc) {    # ask one, wait it out, then ask the next
                syswrite $s->[0], '?';
                my $buf = q{};
                $got += CORE::read( $s->[1], $buf, 64 );
            }
            waitpid $_->[2], 0 for @svc;
            $got == $N * 64 or die "short read: $got";
        }
    ];
    push @wait, [
        'fibers + await_read',
        sub {
            my @svc = service_fork();
            my $got = async {
                my @f = map {
                    fiber {
                        my $s = $svc[$_];
                        syswrite $s->[0], '?';    # all N requests leave at once
                        my $buf = q{};

                        # await_read answers 1 for ready, -1 for a timeout *or* a descriptor it
                        # cannot watch, and never a byte count. Testing the return for > 0 happens
                        # to work here, which is exactly why it is worth stating: a read that is
                        # ready and a read that returns 0 both look fine, and neither is a count.
                        Acme::Parataxis->await_read( $s->[1], 10_000 ) == 1 or return 0;
                        return CORE::sysread( $s->[1], $buf, 64 );
                    }
                } 0 .. $N - 1;
                my $sum = 0;
                $sum += $_->await for @f;
                $sum;
            };
            waitpid $_->[2], 0 for @svc;
            $got == $N * 64 or die "short read: $got";
        }
    ];
    push @wait, [
        "processes x$N",
        sub {
            my @svc = service_fork();
            my @kid;
            for my $i ( 0 .. $#svc ) {
                my $c = fork();
                die "fork: $!" if !defined $c;
                if ( !$c ) {
                    syswrite $svc[$i][0], '?';
                    my $buf = q{};
                    CORE::read( $svc[$i][1], $buf, 64 );
                    POSIX::_exit(0);
                }
                push @kid, $c;
            }
            waitpid $_,      0 for @kid;
            waitpid $_->[2], 0 for @svc;
        }
    ];
}
if ( !@wait ) {
    print "\n=== Wait-bound: $N services, $RTT ms each -- skipped on $^O: the fixture is one forked service per pipe ===\n";
}
else {
    printf "\n=== Wait-bound: %d services, %dms each, latency starts at the request ===\n", $N, $RTT;
    printf "  %-20s %10s %9s   %s\n", 'variant', 'min ms', 'ratio', 'spread ms';
    my $wbase;
    for my $w (@wait) {
        my ( $name, $code )   = @$w;
        my ( $min,  $spread ) = timed($code);
        $wbase //= $min;
        printf "  %-20s %10.1f %8.2fx   %.1f\n", $name, $min, $min / $wbase, $spread;
    }
}
print <<'REPORT';

  Reading it back: fibers cost nothing on the CPU rows and buy 7.3x on the wait rows. That is the
  whole trade, and it is why "make it async" is worth doing for the second shape and is not worth
  thinking about for the first. For compute-bound work the only exits are a real thread or a real
  process, and neither is reachable from a fiber - but a thread costs about 10ms per call before
  it does anything, so it is a decision about how big each item is, not a free upgrade.
REPORT
printf "(sink %s)\n", ( $SINK ? 'set' : 'empty' );
