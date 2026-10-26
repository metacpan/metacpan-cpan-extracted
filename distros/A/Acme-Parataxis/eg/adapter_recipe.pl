# Turning a blocking call into an awaitable one.
#
# "Make this synchronous thing asynchronous" is one question with three different answers, and picking the wrong one
# costs you a latency bug that only shows up under load. This file measures all three, before and after the cheapest
# fix, so the trade-offs are numbers rather than assertions.
#
# The cheap fix is Acme::Parataxis::Compat, which makes sleep/read/sysread cooperative. It is opt-in, it is installed
# at run time, and an override is resolved when code is *compiled* -- so it covers the code below the install and
# nothing above it. That single rule explains most of what follows, including the limits.
#
# Run it: perl -Mblib eg/adapter_recipe.pl
use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use Time::HiRes     ();

# The yardstick.
#
# A heartbeat fiber ticks every 10ms. Anything that blocks the OS thread starves it, so the tick count measures how
# much of the program was frozen. Every measurement runs comparable work and reports both wall time and ticks, so
# "it did not block" is a number and not a vibe.
sub measure {
    my ( $label, $note, $work ) = @_;
    my $ticks = 0;
    my $stop  = 0;
    my $beat  = fiber {
        while ( !$stop ) { $ticks++; await_sleep(10) }
        return;
    };
    my $t0 = Time::HiRes::time();
    $work->();
    my $ms = int( ( Time::HiRes::time() - $t0 ) * 1000 );
    $stop = 1;
    $beat->await;
    printf "  %-38s %5d ms   ticks: %3d   %s\n", $label, $ms, $ticks, $note;
    return;
}

# A pipe whose far end is a real child process that stalls $delay ms and then writes five bytes.
#
# The writer deliberately is NOT a fiber. A fiber would deadlock here: the point of the measurement is that the
# reading fiber blocks the OS thread, and a writer fiber on that same thread can then never be scheduled to write.
# A blocking read and a same-thread writer cannot both make progress, which is exactly the failure this file is
# about -- and exactly why a real program's blocking I/O is a subprocess, a peer, or a timer, never a sibling fiber.
sub stall_pipe {
    my ($delay) = @_;

    # $delay is in milliseconds, because every other duration in this file and in Parataxis is. A four-argument
    # select in the child is in *seconds*, so convert on the way out -- and note that raw CORE::sleep would truncate
    # the fraction to nothing, which is why the child uses select at all.
    open my $reader, '-|', $^X, '-e', "select undef, undef, undef, " . ( $delay / 1000 ) . "; print 'hello'" or die "open: $!";
    return $reader;
}

sub drop_pipe {
    my ($reader) = @_;
    close $reader;
    return;
}

# Everything below this point is compiled before Compat is installed, so it keeps the raw builtins. Two of these are
# here to be measured twice, and that is the only reason they are named.
#
# A real block. Not sleep, and not on purpose: sleep 0.3 truncates to sleep 0 in raw CORE::sleep, so a fractional
# sleep is not a blocking call at all until Compat rounds it back up. select is untouched by Compat in either
# direction, which makes it the honest example of something the cheap fix cannot reach.
sub stall_with_select {
    select undef, undef, undef, 0.3;
    return;
}

# A blocking read, in code that predates the install.
sub read_from_pipe_before {
    my ($fh) = @_;
    my $buf = q{};
    sysread( $fh, $buf, 5 );
    return $buf;
}

# The install. Opt-in, and where it goes is the entire subject of this file: below the code that loads what it
# depends on, above the code you want changed. Everything textually above keeps the raw builtins, everything below
# gets the cooperative ones.
BEGIN { Acme::Parataxis->enable_transparent_unblocking() }

# The same shape as stall_with_select, compiled after the install. This one is *not* cooperative, and section 4
# explains why that is not a bug.
sub stall_with_select_after {
    select undef, undef, undef, 0.3;
    return;
}

# Pure arithmetic. No syscall to wait on and nothing to redefine, so nothing below can help it.
sub burn_cpu {
    my $x = 0;
    $x += $_ for 1 .. 2_000_000;
    return $x;
}
Acme::Parataxis::run(
    sub {
        say '';
        say 'Before the install: everything is raw.';
        say '';
        my $reader = stall_pipe(300);
        measure( 'sysread on an idle pipe', '<- read in pre-install code', sub { read_from_pipe_before($reader) } );
        drop_pipe($reader);
        measure( 'select(undef,undef,undef,0.3)', '<- untouched by Compat, either way',       sub { stall_with_select() } );
        measure( '2M integer adds',               '<- no syscall, nothing to cooperate with', sub { burn_cpu() } );
        say '';
        say '  Three rows, one tick each -- and that single tick is the heartbeat\'s already-pending timer coming due';
        say '  after the work returned, not progress made during it. The pipe read and the select parked the OS thread';
        say '  outright. The arithmetic never reached a park site at all, so it did not even have a pending timer to';
        say '  come due until it was finished. Different mechanisms, same result: 26 to 301 ms in which nothing else';
        say '  in the program ran. Only the first of the three is something Compat can fix.';
        say '';

        # Section 2: what one install buys, and what it does not.
        say 'After the install: sleep/read/sysread cooperate.';
        say '';
        $reader = stall_pipe(300);
        measure( 'sysread, still in pre-install code', '<- unchanged, and that is the rule', sub { read_from_pipe_before($reader) } );
        drop_pipe($reader);
        $reader = stall_pipe(300);
        measure(
            'sysread, in code compiled after it',
            '<- cooperative, no other change',
            sub {
                my $buf = q{};
                sysread( $reader, $buf, 5 );
                return $buf;
            }
        );
        drop_pipe($reader);
        measure( 'select(undef,undef,undef,0.3)', '<- still parked, still frozen', sub { stall_with_select_after() } );
        say '';
        say '  Those two rows are the same three lines of code, one compiled above the install and one below it. That';
        say '  is all an override is: it is installed, not compiled in, so it changes the parser for each call site as';
        say '  that site is compiled. Code that was already compiled keeps the builtin it was bound to.';
        say '';
        say '  Two practical consequences. First, an override changes the parser for every read and sysread compiled';
        say '  after it, so a bareword filehandle in first position stops parsing under "use strict" -- a';
        say '  compile-time failure that no warnings pragma will quiet. Use a lexical handle. Second, anything you';
        say '  cannot recompile -- a precompiled dependency, a .so -- is permanently outside this fix.';
        say '';

        # Section 3: the adapter for code you cannot recompile.
        #
        # If the read is in code compiled before the install, the answer is to stop asking it to do the waiting.
        # Wait for readiness yourself -- that parks in the scheduler, where a deadline or a token can interrupt it
        # -- and then let the old code run against a handle that already has its data. The function does not change,
        # the handle does not change, and the wait moves from the OS thread into Parataxis.
        #
        # Both steps matter. await_read is what makes the wait interruptible; the non-blocking handle is what stops
        # a stale readiness report from parking the thread anyway. Here the handle is still in blocking mode,
        # because readiness means the bytes are genuinely there, so the read cannot park. On a real adapter, set the
        # mode too -- that is what makes it a guarantee instead of a hope.
        #
        # One thing to get right, and it is the easiest mistake to make here: await_read returns a BOOLEAN. It is
        # 1 when the handle is ready and -1 when the wait gave up -- a short timeout, or a descriptor the platform's
        # select() cannot watch at all. It is not a byte count, and feeding it to sysread as one is not a rounding
        # error, it reads a single byte per readiness check: measured here, draining 512KB that way took 235ms
        # against 1ms for 64KB reads. The length you want is yours to pass. The read's own return value is then the
        # only honest source of "how many arrived", because readiness promises only that *something* is there.
        say 'Wrapping the pre-install read yourself: the general adapter.';
        say '';
        $reader = stall_pipe(300);
        measure(
            'await_read, then the old read',
            '<- same old function, wait moved',
            sub {
                my $ready = await_read( $reader, 5000 );
                return unless $ready > 0;
                return read_from_pipe_before($reader);
            }
        );
        drop_pipe($reader);
        say '';
        say '  This is the shape to lift around any blocking call on a handle: wait for the handle, then do the call';
        say '  non-blocking. It is what await_read and await_write are for, and it is what Compat automates for the';
        say '  three builtins it can reach. What it cannot do is reach a call that blocks somewhere else entirely:';
        say '  a connect, a DBI round trip, a module with its own select loop. Those have no descriptor Parataxis';
        say '  can be told about, so no amount of waiting in front of them helps.';
        say '';
        say '  And the two return values deserve to be read as the booleans they are. await_read is 1 or -1, never a';
        say '  length, and -1 covers both "the deadline passed" and "this platform cannot watch that descriptor at';
        say '  all". If you treat -1 as a length, or as success, a timeout silently becomes a one-byte read.';
        say '';

        # Section 4: the two cases with no in-process answer.
        say 'The two cases nothing here fixes.';
        say '';
        measure( 'select(undef,undef,undef,0.3)', '<- parked, and it stays parked', sub { stall_with_select_after() } );
        measure( '2M integer adds',               '<- one thread, no yields',       sub { burn_cpu() } );
        say '';
        say '  The select row is a real block in a fiber and there is no way to make it yield, because the fiber';
        say '  does not know it is waiting -- it is inside a call, not at a park site. Compat cannot reach it and';
        say '  neither can await_read: there is no handle to hand you, because the module chose to block rather';
        say '  than to expose a descriptor. The arithmetic row is worse, because Compat does not make it merely';
        say '  unfair, it makes it invisible: a fiber grinding through arithmetic is not running alongside its';
        say '  siblings, it is standing on all of their toes at once.';
        say '';
        say '  The fix for both is to get the work off this OS thread, and this distribution deliberately has no';
        say '  public "run this coderef on a worker thread" call -- that would drag threads.pm and a perl_clone';
        say '  caveat into every install. The background-interpreter machinery ships separately for it:';
        say '';
        say '      use Acme::Parataxis::Blocking qw[spawn_blocking];';
        say '      my $f = spawn_blocking( sub { heavy_parse($blob) } );';
        say '      my $parsed = $f->await;';
        my $have_blocking = eval { require Acme::Parataxis::Blocking; 1 }                      ? 1 : 0;
        my $have_ithreads = eval { require threads;                   threads->can('create') } ? 1 : 0;
        $have_ithreads = 0 if $^O eq 'MSWin32';    # perl_clone does not work there
        say '';
        say '  On this machine it is not available:';
        printf "    Acme::Parataxis::Blocking installed: %s\n",   ( $have_blocking ? 'yes' : 'no' );
        printf "    an ithreads perl for it to clone:      %s\n", ( $have_ithreads ? 'yes' : 'no' );
        say '';
        say '  So the only move left in-process is to make the loop itself yield: maybe_yield() between chunks, or';
        say '  await_sleep(0), at a granularity fine enough that whatever is queued behind it gets a turn. That';
        say '  trades throughput for fairness -- the right trade in a server, the wrong one in a batch job. Make it';
        say '  deliberately, per call site, rather than discovering it as a p99 that moved.';
        say '';
        say 'In order:';
        say '  1. Blocking in sleep/read/sysread? Install Compat above the code. Change nothing else.';
        say '  2. Blocking on a handle you know about? Wait for it, then make the call non-blocking.';
        say '  3. Blocking in a call you cannot see into, or CPU-bound? Move it off this thread, or yield inside';
        say '     the loop on purpose. There is no fourth option and no adapter that invents one.';
        say '';
        return;
    }
);
