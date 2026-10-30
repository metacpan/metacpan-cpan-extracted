use v5.40;
use Test2::V1 -ipP;
use Config;
use Time::HiRes qw[time];

# spawn_blocking_fork: the CPU-offload path for a perl with no thread support. The thread-backed spawn_blocking has its
# own test file; this one exists because on a non-ithreads perl that file skips entirely, and it is precisely on such a
# perl that this entry point has to work.
BEGIN {
    plan
        skip_all => 'spawn_blocking_fork requires a perl that can fork (d_fork)',
        1
        if !( defined $Config{d_fork} && $Config{d_fork} eq 'define' );
    plan
        skip_all => 'spawn_blocking_fork is not available on MSWin32 (perl\'s fork() is a threads.pm emulation)',
        1
        if $^O eq 'MSWin32';
}
use blib;
use Acme::Parataxis qw[run fiber await_sleep with_timeout];
use Acme::Parataxis::Future;
use Acme::Parataxis::Blocking qw[spawn_blocking_fork set_max_blocking_forks max_blocking_forks kill_blocking_fork];

# Deterministic CPU work: no wall-clock, no sleeping, and a result that depends on the arguments so a crossed payload
# is visible rather than plausible.
sub burn ( $n, $tag ) {
    my $s = 0;
    $s += $_ % 7 for 1 .. $n;
    return "$tag:$s:$$";
}
subtest 'the fork cap is configurable, but only before the pool is used' => sub {
    is max_blocking_forks(),      4, 'the default fork cap is 4';
    is set_max_blocking_forks(2), 2, 'set_max_blocking_forks() returns the new cap';
    is max_blocking_forks(),      2, 'and it took effect';
    like dies { set_max_blocking_forks(0); 1 }, qr[positive integer], 'a non-positive cap croaks';
};
subtest 'the whole point: CPU work runs off the scheduler with no threads anywhere' => sub {
    my $t_before = exists $INC{'threads.pm'} ? 1 : 0;
    my $rv       = run(
        sub {
            my $f = spawn_blocking_fork( sub { burn( 200_000, 'solo' ) } );
            fiber { await_sleep(15) };    # the scheduler must keep running while the child works
            return $f->await;
        }
    );
    like $rv, qr/^solo:\d+:\d+$/, 'the closure result arrived through a Future';
    isnt $rv =~ /(\d+)$/ ? $1 : 0, $$, 'the work really ran in another process';
    ok !$t_before                        && !exists $INC{'threads.pm'},      'no threads.pm was loaded, on a perl that may not have ithreads';
    ok !exists $INC{'threads/shared.pm'} && !exists $INC{'Thread/Queue.pm'}, 'neither threads::shared nor Thread::Queue was loaded';
};
subtest 'the caller keeps running while the child burns' => sub {
    my ( $at, $done ) = ( [], 0 );
    my $rv = run(
        sub {
            # The child is given a wall-clock budget rather than a loop count, and reports the window it was actually
            # running in, so the bystander's progress can be compared against the child's lifetime rather than against
            # a tick count.
            my $t0   = time;
            my $secs = 1;

            # Time::HiRes::time() named in full, for the same reason as in the pool-cap subtest: an imported `time` is
            # not inherited by the forked child, so naming the sub-second clock explicitly is what makes the window this
            # child reports usable for the comparison below.
            my $f = spawn_blocking_fork(
                sub {
                    my $start = Time::HiRes::time();
                    my $end   = $start + $_[0];
                    my $s     = 0;
                    while ( Time::HiRes::time() < $end ) { $s += $_ % 7 for 1 .. 20_000 }
                    return [ $s, $start, Time::HiRes::time() ];
                },
                $secs
            );
            fiber {    # a bystander fiber that only makes progress if the loop is not blocked on the child
                while ( !$done && time - $t0 < $secs + 1 ) {
                    await_sleep(20);
                    push @$at, time;
                }
            };
            my $v = $f->await;
            $done = 1;
            return { v => $v, elapsed => time - $t0 };
        }
    );
    like "$rv->{v}[0]", qr/^\d+$/, 'the slow closure still returned its result';
    cmp_ok $rv->{elapsed}, '>=', 0.9, sprintf( 'the caller really waited for the child (%.2fs)', $rv->{elapsed} );

    # Deliberately not "at least N wakeups in N/20ms": timer granularity is the OS's business, and macOS resolves a
    # 20ms sleep at roughly 90ms, which turned a tick-count assertion into a platform test. What matters is that the
    # bystander was scheduled *while the child was still working*, so its wake times are compared against the window
    # the child reported for itself. A run loop blocked on the child could only wake after that window closed.
    my ( $start, $end ) = @{ $rv->{v} }[ 1, 2 ];
    my @inside = grep { $_ >= $start && $_ <= $end } @$at;
    cmp_ok scalar @inside, '>=', 3, sprintf( 'the bystander fiber ran %d times inside the childs window', scalar @inside );
SKIP: {
        skip 'nothing to measure without a wake inside the window, which the assertion above reports', 1 if !@inside;

        # A loop blocked on the child could only wake at the far end of the window, so the first wake landing in its
        # first half is the part that distinguishes "kept running" from "was released once at the end". The half is a
        # margin, not a specification: macOS resolves a 20ms sleep at roughly 90ms, and a loaded runner can be
        # coarser still.
        cmp_ok $inside[0], '<', $start + ( $end - $start ) / 2,
            sprintf(
            'and its first wake inside that window came %.0fms into a %.0fms window',
            ( $inside[0] - $start ) * 1000,
            ( $end - $start ) * 1000
            );
    }
};
subtest 'marshalling: args, structured results, and copy-in copy-out' => sub {
    my $rv = run(
        sub {
            my $f = spawn_blocking_fork( sub { my ( $a, $b ) = @_; return { sum => $a + $b, list => [ $a, $b ] } }, 20, 22 );
            return $f->await;
        }
    );
    is $rv->{sum},  42,         'explicit args arrive in the closure';
    is $rv->{list}, [ 20, 22 ], 'a nested structure crosses back intact';
    my $before = 'parent-value';
    my $mutate = run(
        sub {
            return spawn_blocking_fork(
                sub {
                    my $seen = $before;
                    $before = 'child-value';    # in the child's copy of memory, which the parent cannot see
                    return $seen;
                }
            )->await;
        }
    );
    is $mutate, 'parent-value', 'the closure saw a copy taken at the fork';
    is $before, 'parent-value', 'and its writes to that copy did not come back';
};
subtest 'errors: die, an unshareable result, and a killed child' => sub {

    # Future->await returns the result or dies on the error, so every one of these wants its own eval.
    like run(
        sub {
            my $r = eval {
                spawn_blocking_fork( sub { die "boom-$_[0]" }, 'x' )->await;
            };
            $@;
        }
        ),
        qr/boom-x/, 'a die() in the closure becomes the Future error';
    my $unshareable = run(
        sub {
            my $r = eval {
                spawn_blocking_fork(
                    sub {
                        sub {1}
                    }
                )->await;
            };
            $@;
        }
    );
    like $unshareable, qr/CODE|Can't store/i, 'an unshareable result becomes the error rather than a crash';

    # The one thing the thread pool cannot do. A child doing real work is a real process, so it can be signalled.
    my ( $killed_fut, $killed_ok, $elapsed );
    my $rv = run(
        sub {
            my $f = spawn_blocking_fork(
                sub {
                    my $end = time + 600;
                    my $s   = 0;
                    while ( time < $end ) { $s += $_ % 7 for 1 .. 50_000 }
                    $s;
                }
            );
            await_sleep(250);    # let the child get well into the work
            $killed_ok  = kill_blocking_fork($f);
            $killed_fut = $f;
            my $t0 = time;
            my $r  = eval { $f->await };
            $elapsed = time - $t0;
            return { err => ( $@ || '(no error)' ), leaked_a_result => ( defined $r ? 1 : 0 ) };
        }
    );
    ok $killed_ok, 'kill_blocking_fork() signalled a running child';
    like $rv->{err}, qr/died on signal|never delivered/, 'a signalled child resolves the Future with an error';
    is $rv->{leaked_a_result}, 0, 'and not with a bogus result';
    cmp_ok $elapsed, '<', 30, "the Future resolved promptly after the signal (${elapsed}s)";
    ok $killed_fut->is_ready, 'the Future is ready once the child is reaped';
    my $gone = run(
        sub {
            my $f = spawn_blocking_fork( sub {'done'} );
            $f->await;
            return kill_blocking_fork($f);
        }
    );
    ok !$gone, 'kill_blocking_fork() on a finished child reports false rather than signalling a stranger';

    # Two children in flight at once: signalling one must leave the other running and its result intact. Note this is
    # a co-existence check, not a lookup oracle - a deliberately wrong lookup that just picked whichever pid the hash
    # yielded first still passed it (measured), because the doomed child happened to be the first inserted. What it
    # does catch is a lookup that returns a stale or unrelated pid, or a signal sent more broadly than one child.
    my $pair = run(
        sub {
            my $doomed = spawn_blocking_fork(
                sub {
                    my $end = time + 600;
                    my $s   = 0;
                    while ( time < $end ) { $s += $_ % 7 for 1 .. 50_000 }
                    $s;
                }
            );
            my $innocent = spawn_blocking_fork( sub { my $s = 0; $s += $_ % 7 for 1 .. 60_000; "survivor:$s" } );
            await_sleep(250);
            my $delivered    = kill_blocking_fork($doomed);
            my $survivor     = eval { $innocent->await };
            my $survivor_err = $@;
            my $doomed_r     = eval { $doomed->await };
            return { delivered => $delivered, survivor => $survivor, survivor_err => $survivor_err, doomed_err => $@ };
        }
    );
    ok $pair->{delivered}, 'the signal was delivered';
    like $pair->{survivor}, qr/^survivor:\d+$/, 'and the other child in flight finished normally, undisturbed';
    is $pair->{survivor_err}, '', 'with no error of its own';
    like $pair->{doomed_err}, qr/died on signal|never delivered/, 'while the signalled one resolved with an error';
};
subtest 'a result larger than the pipe buffer still arrives' => sub {
    my $rv = run(
        sub {
            return spawn_blocking_fork( sub { 'x' x 1_000_000 } )->await;
        }
    );
    is length($rv), 1_000_000, 'a 1MB payload crossed the pipe without deadlocking';
    ok $rv !~ /[^x]/, 'and arrived uncorrupted';
};
subtest 'the process pool is bounded by set_max_blocking_forks' => sub {
    my $rv = run(
        sub {
            # Time::HiRes::time() is named in full so the window each child reports is sub-second, and the comment
            # below the assertions says why the overlap test must not demand concurrency it cannot get everywhere.
            my @fs = map {
                spawn_blocking_fork( sub { my $t0 = Time::HiRes::time(); burn( 400_000, 'w' ); return [ $t0, Time::HiRes::time(), $$ ] } );
            } 1 .. 6;
            return [ map { $_->await } @fs ];
        }
    );

    # Concurrency cannot be counted with a shared integer here: the children are separate processes and a counter
    # they increment lands in their own copy, which is precisely the copy-in copy-out this test keeps asserting.
    # So each child reports the wall-clock window it was actually running in, and the depth is computed here.
    is scalar @$rv,                                       6, 'all six closures completed';
    is scalar( keys %{ { map { $_->[2] => 1 } @$rv } } ), 6, 'and each ran in its own process';

    # The cap is 2, so at no instant may three of them be running. Walk the endpoints and take the depth.
    #
    # What is deliberately NOT asserted is that the closures *did* overlap. The permit is taken in the parent at spawn
    # and released only once the parent's harvester has read the payload and reaped the child, so the real ceiling on
    # concurrency is parent-side teardown cost, not child work. On Linux fork and reap are cheap enough that two
    # children overlap; on a macOS x64 leg every child finished before the next one started, which reported zero
    # overlapping pairs and a peak depth of 1 while the pool was obeying its cap exactly as written. Asserting overlap
    # would have been asserting that macOS forks as fast as Linux's, which is a claim about the OS, not about this
    # code. Depth 1 is a legitimate outcome of a working cap: it means the batch serialised, which is slower and still
    # correct. The ceiling is the contract; how much of it gets used is the platform's business.
    my @events = map { ( [ $_->[0], +1 ], [ $_->[1], -1 ] ) } @$rv;
    my ( $depth, $high ) = ( 0, 0 );
    for my $e ( sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @events ) {
        $depth += $e->[1];
        $high = $depth if $depth > $high;
    }
    cmp_ok $high, '<=', 2, "never more than the cap of 2 ran at once (peak depth $high)";
    like dies { set_max_blocking_forks(8); 1 }, qr[before the first spawn_blocking_fork], 'the cap cannot be changed once the pool is in use';
};
subtest 'croaks where the contract says it must' => sub {
    like dies { spawn_blocking_fork('nope'); 1 }, qr/spawn_blocking_fork/, 'without a CODE ref';
    like dies {
        spawn_blocking_fork( sub {1} );
        1;
    }    # genuinely outside any run
    , qr/inside a scheduled fiber/, 'outside a scheduled fiber';
    like dies {
        run(
            code => sub {
                spawn_blocking_fork( sub {1} );
            },
            virtual => 1
        );
        1;
    }, qr/wall-clock|mock clock/, 'under the mock clock of run(virtual => 1)';
    like dies {
        run( sub { kill_blocking_fork('not a future') } );
        1;
    }, qr/Future/, 'kill_blocking_fork() without a Future';
};
subtest 'composes with with_timeout, and under an attached driver' => sub {
    like run(
        sub {
            # with_timeout takes milliseconds, not seconds: a 5 would be a 5ms deadline for a 4ms closure, which
            # fails about one time in ten and looks exactly like a lost wakeup.
            return with_timeout(
                5000,
                sub {
                    spawn_blocking_fork( sub { burn( 120_000, 'timed' ) } )->await;
                }
            );
        }
        ),
        qr/^timed:\d+:/, 'the result came back under an enclosing with_timeout';
    subtest Mojo => sub {
        skip_all 2, 'Mojo::IOLoop not installed' unless eval { require Mojo::IOLoop; 1 };
        my ( $driver_rv, $ticked );
        Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
        $driver_rv = run(
            sub {
                my $f = spawn_blocking_fork( sub { burn( 300_000, 'loop' ) } );
                fiber { await_sleep(20); $ticked = 1 };
                return $f->await;
            }
        );
        Acme::Parataxis->detach_loop;
        like $driver_rv, qr/^loop:\d+:/, 'the result arrived with the harvester riding the loop';
        ok $ticked, 'fibers still cooperated under the driver while the child ran';
    }
};

# A child that is never reaped is a zombie, and a suite that leaks six of them per run is a suite that eventually
# trips a process limit rather than failing where the bug is.
subtest 'no children are left behind' => sub {
    my $rv = run(
        sub {
            return [
                map {
                    spawn_blocking_fork( sub {$_} )->await
                } 1 .. 4
            ];
        }
    );
    is $rv, [ 1, 2, 3, 4 ], 'four small closures all completed';
    opendir( my $dh, '/proc' ) or plan skip_all => 'no /proc on this platform';
    my @zombies;
    while ( defined( my $d = readdir($dh) ) ) {
        next if $d !~ /\A[0-9]+\z/;
        open( my $fh, '<', "/proc/$d/stat" ) or next;
        my $line = <$fh>;
        close $fh;
        next if !defined $line;

        # field 3 is state, field 4 is ppid
        my ( $state, $ppid ) = $line =~ /\)\s+(\S)\s+(\d+)/;
        push @zombies, $d if defined $state && $state eq 'Z' && defined $ppid && $ppid == $$;
    }
    closedir $dh;
    is scalar @zombies, 0, "every forked child was reaped (no zombies: @zombies)";
};
#
done_testing();
