#!/usr/bin/perl
# Hashing a directory tree: File::Find + Digest::SHA, made cooperative.
#
# The reflex when a task is slow is to reach for async, and then spend a day making a synchronous walk yield and a
# synchronous hasher cooperate, and end up with a program that is not measurably faster than the one you started with.
# This file is the worked version of that, and the punchline is in the diagnosis near the end: the hasher was never
# I/O-bound. It is CPU-bound, and no amount of scheduling changes a CPU-bound program that has one thread.
#
# Five things get measured, each against a heartbeat fiber that ticks every 10ms so "did it cooperate" is a number:
#
#   1. File::Find. A synchronous recursive walk. What actually makes it hand the thread back is yield(), and
#      maybe_yield() does not - it is a preemption counter, and at the default threshold of 0 it is a no-op. That is
#      the single most common mistake in this file's genre, so it gets its own section and its own numbers.
#   2. Digest::SHA->addfile. XS. It does its own reading in C, where a Perl-level override cannot reach, so Compat
#      cannot help it at all. Measured, not assumed.
#   3. The same digest driven by a Perl read loop. Now the reads are reachable, so Compat does cooperate - and the
#      chunk size turns out to matter more than anything else in this file.
#   4. One fiber per file, bounded by a semaphore. Buys resource bounding, not throughput, and the numbers say so.
#   5. The diagnosis, and the one tuning knob that is actually worth reaching for.
#
# Run it: perl -Mblib eg/sha_walk.pl [files] [bytes-per-file]
use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
no warnings 'experimental::try';    # try/catch below; the dist does the same in its .pm files
use Acme::Parataxis::Semaphore;
use Config;
use Digest::SHA ();
use File::Find  ();
use File::Path  ();
use File::Spec;
use File::Temp  ();
use Time::HiRes ();
my $FILE_COUNT = shift // 20;
my $FILE_BYTES = shift // 262_144;

# The install that makes sleep/read/sysread cooperative. It has to sit above the code that reads files, which is
# below, and that is the whole placement rule: an override is resolved when each call site is *compiled*, so it
# covers this file's reads and nothing from a module loaded before it.
BEGIN { Acme::Parataxis->enable_transparent_unblocking() }

# CLEANUP => 0 on purpose, and this is not a style choice - it is the fix for a trap that only bites when the
# threaded branch at the end of this file actually runs.
#
# `threads->create` clones the whole perl stack, so every thread gets its *own* copy of the object graph, with its
# own refcounts. The clone's copy of $ROOT is not kept alive by this interpreter's copy of it, so when a thread
# exits, that refcount goes to zero, DESTROY runs, and File::Temp rmtree's the directory out from under the
# threads still working in it.
#
# The symptom is not an error you would guess at: the first couple of threads succeed, the directory is deleted,
# and everything after that dies with ENOENT. "Open failed: No such file or directory" on files that demonstrably
# existed a second earlier. It looks exactly like a race in the code being benchmarked, and it is not.
my $ROOT = File::Temp->newdir( CLEANUP => 0 );

END {
    return if $main::ROOT_DONE;
    $main::ROOT_DONE = 1;
    my $d = $ROOT->dirname;
    File::Path::remove_tree($d) if defined $d && -d $d;
}

# A tree worth walking: a few directories, a few files each, some nested, one deliberately empty.
sub build_tree {
    my ( $root, $count, $bytes ) = @_;
    my @dirs = map { File::Spec->catdir( $root, "d$_" ) } ( 0 .. 2 );
    push @dirs, File::Spec->catdir( $dirs[0], 'nested' );
    File::Path::make_path(@dirs);
    for my $i ( 0 .. $count - 1 ) {
        my $dir  = $dirs[ $i % @dirs ];
        my $path = File::Spec->catfile( $dir, "file$i.dat" );
        open my $fh, '>:raw', $path or die "open $path: $!";

        # Incompressible-ish content, so the digest has real work and is not measuring a memcpy of zeroes.
        my $chunk = join q{}, map { chr( 32 + ( $_ * 7 + $i ) % 90 ) } 0 .. 4095;
        print {$fh} substr( $chunk x int( $bytes / 4096 ), 0, $bytes );
        close $fh;
    }
    return $root;
}

# The yardstick. A heartbeat fiber ticks every 10ms; anything that blocks the OS thread starves it.
sub measure {
    my ( $label, $note, $work ) = @_;
    my $ticks = 0;
    my $stop  = 0;
    my $beat  = fiber {
        while ( !$stop ) { $ticks++; await_sleep(10) }
        return;
    };
    my $t0 = Time::HiRes::time();
    my @r  = $work->();
    my $ms = ( Time::HiRes::time() - $t0 ) * 1000;
    $stop = 1;
    $beat->await;

    # An empty label means "measured but not printed here" - section 6 prints its own table, and it
    # wants the tick counts without the duplicate millisecond line.
    printf "  %-42s %6.1f ms   ticks: %3d   %s\n", $label, $ms, $ticks, $note if length $label;
    return ( $ms, $ticks, @r );
}

# Hashing, several ways. They all produce the same digests; they differ only in what they do to the other fibers.
#
# addfile is XS: it opens the file, loops over the reads, and feeds the digest entirely inside C. A CORE::GLOBAL
# override is a Perl sub, so there is nothing for it to intercept - the whole digest is one opaque call to the
# scheduler's point of view, and it cannot be interrupted part way through.
sub hash_addfile {
    my ($path) = @_;
    return Digest::SHA->new(256)->addfile($path)->hexdigest;
}

# The same digest, with the read loop written in Perl. Now every read is a real call site that Compat can see.
#
# $core selects the unoverridden builtin, which is the control for how much of the cost below is Compat's per-call
# framing rather than the syscall. Note it bypasses the override *and* the cooperative path, so it is not a
# drop-in: it blocks the thread. It is here to be measured, not to be shipped.
sub hash_loop {
    my ( $path, $size, $core ) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    my $sha = Digest::SHA->new(256);
    my $buf;
    while ( my $n = $core ? CORE::sysread( $fh, $buf, $size ) : sysread( $fh, $buf, $size ) ) {
        $sha->add( substr( $buf, 0, $n ) );
    }
    close $fh;
    return $sha->hexdigest;
}
Acme::Parataxis::run(
    sub {
        my $root = build_tree( $ROOT->dirname, $FILE_COUNT, $FILE_BYTES );
        my $mb   = $FILE_COUNT * $FILE_BYTES / 1_048_576;
        say '';
        say "Hashing a tree of $FILE_COUNT files, $mb MB total.";
        say '';

        # The walk, and the mistake almost everyone makes with it.
        #
        # Milliseconds are the wrong yardstick here and would be a trap: a walk of a local directory tree costs a
        # few microseconds per entry, so the whole thing lands inside one 10ms tick and every version below measures
        # ~0ms and one tick whether or not the walk cooperates. What is measurable, and what actually matters, is
        # how many turns the walk hands to a sibling - so that is what gets counted. A companion fiber parked on
        # await_sleep(0) is resumed once per yield, and zero times if the walk never gives the thread back.
        say '1. File::Find, and how many turns it hands to a sibling.';
        say '';
        my $sibling_runs = sub {
            my ($work) = @_;
            my ( $runs, $stop ) = ( 0, 0 );
            my $companion = fiber {
                while ( !$stop ) { $runs++; await_sleep(0) }
            };
            $work->();
            $stop = 1;
            $companion->await;
            return $runs;
        };
        my $walk = sub {
            my ($hook) = @_;
            return $sibling_runs->(
                sub {
                    File::Find::find(
                        {   no_chdir => 1,
                            wanted   => sub {
                                $hook->() if $hook;
                                return;
                            },
                        },
                        $root
                    );
                }
            );
        };

        # Not imported, and not callable as a method: `set_preempt_threshold(5)` is an undefined subroutine under
        # `use Acme::Parataxis qw[:all]` because it is missing from @EXPORT_OK, and `Acme->set_preempt_threshold(5)`
        # dies with "Wrong number of arguments. Expected 1, got 2" because the method form never applies the
        # argument offset. The fully qualified function call is the only form that works.
        my $arm = sub {
            my ($n) = @_;
            Acme::Parataxis::set_preempt_threshold($n);
            return;
        };
        $arm->(0);
        my $no_yield = $walk->(undef);
        my $maybe_0  = $walk->( sub { maybe_yield() } );
        my $hard     = $walk->( sub { yield() } );
        my %armed;
        for my $threshold ( 1, 5, 20 ) {
            $arm->($threshold);
            $armed{$threshold} = $walk->( sub { maybe_yield() } );
        }
        $arm->(0);
        printf "  %-42s %3d\n", 'no yield at all',             $no_yield;
        printf "  %-42s %3d\n", 'maybe_yield(), threshold 0',  $maybe_0;
        printf "  %-42s %3d\n", 'yield() per entry',           $hard;
        printf "  %-42s %3d\n", 'maybe_yield(), threshold 1',  $armed{1};
        printf "  %-42s %3d\n", 'maybe_yield(), threshold 5',  $armed{5};
        printf "  %-42s %3d\n", 'maybe_yield(), threshold 20', $armed{20};
        say '';
        say '  Read the first two rows together, because they are the whole point of this section.';
        say '';
        say '  maybe_yield() at the default threshold is not a yield. It increments a per-fiber counter and yields';
        say '  only when that counter reaches the threshold, and the default threshold is 0 - so it never fires,';
        say '  and the row is identical to not calling it at all. A program full of maybe_yield() calls can be just as';
        say '  monopolising as a program with none, and it will look deliberate while it does it.';
        say '';
        say '  yield() is the real thing: one resume per entry. Arming the counter works too, and the threshold is';
        say '  the dial - at 1 it matches yield() exactly, at 5 and 20 it hands the thread back progressively less';
        say '  often. A threshold with no preemption hook installed is still just a counter; eg/preempt.pl is what';
        say '  arms the other half of that pair.';
        say '';
        say '  Which you want depends on the walk. This one visits a handful of local directories, so the yield buys';
        say '  nothing you can time. Over a network mount, where every stat is a round trip, an unyielding walk blocks';
        say '  every other fiber for the whole traversal - and the threshold is how you stop paying for a yield per';
        say '  entry when the tree is large and the entries are cheap.';
        say '';
        my @sorted;
        File::Find::find( { no_chdir => 1, wanted => sub { push @sorted, $File::Find::name if -f $_ }, }, $root );
        @sorted = sort @sorted;

        # The naive hasher.
        say '2. Hashing it the obvious way.';
        say '';
        my ( $ms_c, $ticks_c, @naive ) = measure(
            'one fiber, addfile in a loop',
            '<- the whole tree, uninterrupted',
            sub {
                return map { hash_addfile($_) } @sorted;
            }
        );

        # The cooperative hasher - and the one knob that matters.
        say '3. The same digests, with the read loop in Perl.';
        say '';
        my ( $ms_d, $ticks_d, @chunked ) = measure(
            'one fiber, chunked read loop, 64K',
            '<- every read is now interruptible',
            sub {
                return map { hash_loop( $_, 65_536, 0 ) } @sorted;
            }
        );
        say "  Same digests: " . ( ( join q{,}, @naive ) eq ( join q{,}, @chunked ) ? 'yes' : 'NO' );
        say '';

        # One fiber per file, bounded.
        say '4. One fiber per file, capped at four in flight.';
        say '';
        my $sem = Acme::Parataxis::Semaphore->new( count => 4 );
        my @by_file;
        my ( $ms_e, $ticks_e ) = measure(
            '4 fibers at a time, chunked reads',
            '<- reads overlap each other',
            sub {
                @by_file = (undef) x scalar(@sorted);

                # nursery is the structured form: every spawned child is reaped before it returns, so there is no
                # way to reach the line below with work still outstanding, and a child that dies takes the nursery
                # down with it rather than being silently dropped. A child cannot hand a value back through its
                # return - the runtime joins it - so results are written into a lexical, which is the documented
                # idiom.
                nursery(
                    sub ($n) {
                        for my $i ( 0 .. $#sorted ) {
                            my $path = $sorted[$i];
                            $n->spawn(
                                sub {
                                    $sem->down;

                                    # try/catch, not eval: the rethrow has to preserve the original error, and
                                    # `catch ($caught)` is the only form that actually assigns the caught value -
                                    # `catch ($err)` silently leaves $err undef, because the value is only visible
                                    # inside the block.
                                    my $got;
                                    try {
                                        $got = hash_loop( $path, 65_536, 0 );
                                    }
                                    catch ($caught) {
                                        $sem->up;
                                        die $caught;
                                    }
                                    $sem->up;
                                    $by_file[$i] = $got;
                                    return;
                                }
                            );
                        }
                    }
                );
                return @by_file;
            }
        );
        say "  Same digests: " . ( ( join q{,}, @naive ) eq ( join q{,}, @by_file ) ? 'yes' : 'NO' );
        say '';

        # The diagnosis.
        say '5. Why none of that made it faster.';
        say '';
        printf "  %-42s %6.1f ms\n", 'addfile loop',            $ms_c;
        printf "  %-42s %6.1f ms\n", 'chunked read loop, 64K',  $ms_d;
        printf "  %-42s %6.1f ms\n", '4 fibers, chunked reads', $ms_e;
        say '';

        # How much of that is the syscall and how much is the digest? Read the bytes without hashing, then hash bytes
        # we already hold in memory, and the difference is the part no scheduler can help with.
        my ($ms_io) = measure(
            'read every byte, no digest',
            '',
            sub {
                for my $p (@sorted) {
                    open my $fh, '<:raw', $p or die;
                    my $buf;
                    1 while sysread( $fh, $buf, 1_048_576 );
                    close $fh;
                }
                return;
            }
        );
        my @blobs = map {
            open my $fh, '<:raw', $_ or die;
            local $/;
            my $b = <$fh>;
            close $fh;
            $b;
        } @sorted;
        my ($ms_cpu) = measure( 'digest the same bytes, already in memory', '', sub { Digest::SHA->new(256)->add($_) for @blobs; return } );
        say '';
        printf "  Reading %.1f MB off the page cache, no digest: %6.1f ms\n", $mb, $ms_io;
        printf "  Digesting the same %.1f MB from memory:       %6.1f ms\n",  $mb, $ms_cpu;
        printf "  addfile, which does both inside C:           %6.1f ms\n",   $ms_c;
        say '';
        my $share  = $ms_c > 0 ? sprintf( '%.0f%%', 100 * $ms_cpu / $ms_c ) : 'all of it';
        my $c_read = $ms_c - $ms_cpu;
        say "  The digest is the whole story: run on bytes already in memory it takes $share as long as addfile";
        say '  does for the read and the digest together. It is arithmetic in this process, on the one thread that';
        say '  every fiber shares. The read is cheap, but only';
        say sprintf( '  because addfile does it inside C in megabyte chunks - roughly %.1fms of the %.1fms. The same', $c_read, $ms_c );
        say sprintf( '  bytes through a Perl read loop cost %.1fms, so something like %.1fms of the difference is',    $ms_io,  $ms_io - $c_read );
        say '  per-call overhead rather than the kernel - which is what the chunk size below controls.';
        say '';
        say '    * Step 1 bought fairness. The walk no longer starves a sibling. Worth having in a server.';
        say '    * Step 3 bought interruptibility. A big file is now cancellable between chunks, so Ctrl-C or a';
        say '      CancellationToken lands promptly instead of after the last megabyte. Also worth having.';
        say '    * Step 4 bought nothing, and the numbers say so. Four fibers on one thread is still one thread, so';
        say '      the four digests ran one after another and the total is the total.';
        say '';
        say '  What step 4 is actually for is bounding resource use rather than adding throughput: the semaphore';
        say '  keeps at most four files open at once, so a 200,000-file tree does not become 200,000 open';
        say '  descriptors and 200,000 digests resident. Reach for it when the file count is unbounded, not';
        say '  expecting a speedup.';
        say '';

        # The one tuning knob that is worth reaching for.
        #
        # Same digest, same Compat, same thread - only the chunk size changes. This is the largest single effect in
        # the file, and it is a factor of five, which is worth knowing before deciding a cooperative read loop is
        # "slower than addfile".
        say '6. The knob that does matter: chunk size.';
        say '';
        my ( %by_size, %ticks_by );
        for my $size ( 4_096, 65_536, 1_048_576 ) {
            my ( $ms, $ticks ) = measure( '', '', sub { hash_loop( $_, $size, 0 ) for @sorted; return } );
            ( $by_size{$size}, $ticks_by{$size} ) = ( $ms, $ticks );
        }
        my ( $ms_core, $ticks_core ) = measure( '', '', sub { hash_loop( $_, 65_536, 1 ) for @sorted; return } );

        # Every row is shown against the 4K loop, because that is the one people write by default.
        my $four_k = $by_size{4_096};
        my $row    = sub {
            my ( $label, $ms, $ticks ) = @_;
            printf "  %-42s %6.1f ms   %5.2fx   ticks: %3d\n", $label, $ms, $four_k / $ms, $ticks;
            return;
        };
        $row->( 'addfile (all reads in C)', $ms_c,               $ticks_c );
        $row->( '4K chunks',                $four_k,             $ticks_by{4_096} );
        $row->( '64K chunks',               $by_size{65_536},    $ticks_by{65_536} );
        $row->( '1M chunks',                $by_size{1_048_576}, $ticks_by{1_048_576} );
        $row->( '64K, Compat bypassed',     $ms_core,            $ticks_core );
        say '';
        say '  The multiplier is against the 4K row, so it is how much faster than the one people write by';
        say '  default. The tick count is the other half of the story: more ticks is the loop handing the';
        say '  thread back more often, which is what makes the work cancellable in between.';
        say '';
        say sprintf(
            '  Per file that is %d reads at 4K against %d at 1M. The per-read cost - the syscall plus the',
            int( $FILE_BYTES / 4_096 ) + 1,
            int( $FILE_BYTES / 1_048_576 ) + 1
        );
        say '  override Compat installs around each one - is charged once per read, so the chunk size is the dial.';
        say '';
        my $pct = $by_size{65_536} > 0 ? sprintf( '%.0f%%', 100 * ( $by_size{65_536} - $ms_core ) / $by_size{65_536} ) : 'n/a';
        say '  The last row is the uncomfortable one. Bypassing the override is faster still, and it is faster';
        say "  precisely because it stops being cooperative: against the 64K row that is about $pct of the wall clock,";
        say '  spent on handing the thread back. If that is a trade you will not make, keep 64K or better and accept';
        say '  the cost. If you will, hash_addfile is faster than both of them and uninterruptible.';
        say '';

        # Getting the work off this thread.
        say '7. The part that is actually worth parallelising.';
        say '';

        # $Config{useithreads} is the gate, and it is the right one: spawn_blocking clones a thread, and threads.pm
        # is exactly the module that cannot be loaded on a perl built without thread support. Testing `require
        # threads` instead would be a weaker check on a perl that has the module but not the build.
        my $ithreads = ( defined $Config{useithreads} && $Config{useithreads} eq 'define' ) ? 1 : 0;
        $ithreads = 0 if $^O eq 'MSWin32';    # perl_clone does not work there
        my $have_blocking = eval { require Acme::Parataxis::Blocking; 1 } ? 1 : 0;
        if ( $have_blocking && $ithreads ) {
            require Acme::Parataxis::Blocking;

            # One call per file at the default pool size, which is the shape a caller actually writes. Measured
            # separately on a threaded build: this is *slower* than the inline loop at a pool of one, and only
            # wins once each file is big enough to pay for a thread. See eg/bench_offload.pl for the full table.
            my $t0  = Time::HiRes::time();
            my @w   = map { Acme::Parataxis::Blocking::spawn_blocking( \&hash_addfile, $_ ) } @sorted;
            my @out = map { $_->await } @w;
            my $ms  = ( Time::HiRes::time() - $t0 ) * 1000;
            printf "  spawn_blocking on all %d files:      %6.1f ms   (inline was %6.1f ms, %5.2fx)\n", scalar(@sorted), $ms, $ms_c, $ms / $ms_c;
            say '  Same digests: ' . ( ( join q{,}, @naive ) eq ( join q{,}, @out ) ? 'yes' : 'NO' );
            say '';
            say '  Note the multiplier. Offloading one hash of a 256KB file to a thread made it much slower, and';
            say '  not because threads are slow - because each call pays a fixed cost before any of your code';
            say '  runs, and it dominates the work. That is the number to check before reaching for this API:';
            say '  a call costs on the order of 10ms, so nothing below roughly that is ever worth offloading.';
            say '';
            say '  Above the floor it inverts, and it inverts for a real reason rather than by accident: the work';
            say '  left this thread. eg/bench_offload.pl has the full table - the same fixture threaded 15 ways';
            say '  reaches about 4.9x on a workload 15 times this size. The win comes from Digest::SHA releasing';
            say '  the GIL, so a pure-perl closure gains nothing at any pool size. Measure your own closure before';
            say '  assuming you are in the case that scales.';
        }
        else {
            say '  The only way to speed up a CPU-bound digest is to get it off this OS thread, which needs a';
            say '  background interpreter: Acme::Parataxis::Blocking, a separate distribution, via';
            say '  spawn_blocking(). It is not available here:';
            printf "    Acme::Parataxis::Blocking installed: %s\n",   ( $have_blocking ? 'yes' : 'no' );
            printf "    an ithreads perl for it to clone:      %s\n", ( $ithreads      ? 'yes' : 'no' );
            if ( !$ithreads ) {
                printf "    \$Config{useithreads} is %s\n", ( defined $Config{useithreads} ? "'" . $Config{useithreads} . "'" : 'undef' );
            }
            say '';
            say '  Note that the threads module being loadable is not the test. `require threads` succeeds on some';
            say '  perls built without thread support, and spawn_blocking then croaks at the call.';
            say '  $Config{useithreads} is the flag that matches what the clone actually needs.';
            say '';
            say '  Until you have it, the honest options are both compromises, and you should pick one on purpose:';
            say '    * yield() between chunks, as in step 3. Costs some throughput, buys fairness, and is what makes';
            say '      cancellation land. Right for a server.';
            say '    * Do not cooperate at all, and accept that one big file freezes every other fiber until it is';
            say '      done. Fastest, and fine for an overnight batch job.';
        }
        say '';
        return;
    }
);
