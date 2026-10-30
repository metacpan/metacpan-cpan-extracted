use v5.40;

package Acme::Parataxis::Blocking v0.1.3 {
    use Config;
    use Exporter        qw[import];
    use Carp            qw[croak];
    use Acme::Parataxis qw[fiber await_sleep await_read];
    use Acme::Parataxis::Future;
    use Acme::Parataxis::Semaphore;
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                spawn_blocking set_max_blocking_threads max_blocking_threads
                spawn_blocking_fork set_max_blocking_forks max_blocking_forks kill_blocking_fork
                ]
        ]
    );

    # spawn_blocking interpreter pool: at most $SB_MAX background interpreters run closures at once, bounded by an
    # Acme::Parataxis::Semaphore created on first use (PARATAXIS_SB_THREADS overrides the default 4).
    my $SB_MAX = do { my $e = $ENV{PARATAXIS_SB_THREADS}; ( defined $e && $e =~ /\A[1-9][0-9]*\z/ ) ? int($e) : 4 };
    my $SB_PERMITS;    # Acme::Parataxis::Semaphore, capacity $SB_MAX; down() before a thread spawn, up() at reap

    # spawn_blocking_fork process pool: a separate semaphore and a separate cap, because a forked child and a cloned
    # interpreter are different resources and coupling them would make one starve the other silently.
    my $SBF_MAX = do { my $e = $ENV{PARATAXIS_SBF_FORKS}; ( defined $e && $e =~ /\A[1-9][0-9]*\z/ ) ? int($e) : 4 };
    my $SBF_PERMITS;     # Acme::Parataxis::Semaphore, capacity $SBF_MAX; down() before a fork, up() at reap
    my %SBF_CHILDREN;    # Future address => the pid of the child that will resolve it, so kill_blocking_fork() can find it

    # Read exactly $want bytes off a pipe, parking between chunks, and return what arrived. Deliberately not built on
    # await_read's return value: that is a readiness flag (1) rather than a byte count, and a closed write end reports
    # readiness too, so 0 bytes off sysread here is the only honest EOF signal. A negative readiness means the child is
    # simply still busy, which is not an error and never ends the read.
    sub _fork_read_exactly ( $fh, $want, $timeout ) {
        my $buf = '';
        while ( length($buf) < $want ) {
            my $ready = await_read( $fh, $timeout );

            # The deadline came round with the child still running: its own runtime is the only clock that matters here
            next if $ready < 0;
            my $n = sysread( $fh, my $chunk, $want - length($buf) );
            last if !defined($n) || $n == 0;    # write end closed, or the pipe broke
            $buf .= $chunk;
        }
        return $buf;
    }

    # Reap a child without blocking the run loop, and return its exit status as (exited, status, signal).
    # WNOHANG in a park loop rather than a blocking waitpid: the loop's other fibers have to keep running.
    sub _fork_reap ($pid) {
        my $reaped = 0;
        while ( ( $reaped = waitpid( $pid, POSIX::WNOHANG() ) ) == 0 ) { await_sleep(1) }
        return ( 1, $? >> 8, $? & 127 ) if $reaped == $pid;
        return ( 0, undef,   undef );                         # already reaped by something else, or not ours
    }

    # Index at which user arguments start in @_: 0 when it is a plain call, 1 when $_[0] is a self (package name or
    # blessed object). Mirrors the dance in Acme::Parataxis: read $_[0] instead of shifting, so calling this never
    # reifies the caller's pad @_. A reified @_ left behind in a parked frame trips pp_entersub's invariants when a
    # different fiber later enters the same sub at the same depth.
    sub _arg_offset {
        my $self = $_[0];
        return ( defined $self && ( ( ref $self || $self ) eq __PACKAGE__ || ( builtin::blessed($self) && $self->isa(__PACKAGE__) ) ) ) ? 1 : 0;
    }

    # Run a CPU-bound closure on a dedicated background Perl interpreter, with its result arriving as a normal Future.
    #
    # The C pool cannot do this: those workers execute C waits (sleep/read/write) only, so a real Perl closure needs a
    # real ithread. Each call therefore clones the interpreter with threads->create (the whole point of Loom's
    # worker_threads and the honest thread-per-task trade: the dense clone cost is paid per call, but the closure runs
    # in complete isolation and the scheduler is never touched while it does). The bounds and the copy-in/copy-back
    # rules are deliberate:
    #
    #   * capacity - at most set_max_blocking_threads() interpreters run at once (default 4, PARATAXIS_SB_THREADS or a
    #     call before first use change it). Excess spawn_blocking calls park the *calling* fiber on a Semaphore until
    #     a slot frees, so the bound is a true concurrency cap like the C pool's.
    #   * copy-in   - the closure sees only a snapshot of the caller's world taken at spawn: its args (threads->create
    #     args) and whatever its captured lexicals held at that instant. Threads share nothing, so in-place mutations
    #     and later writes to shared/holder state never leak back.
    #   * copy-back - the return value must survive threads::shared::shared_clone: plain scalars and nested
    #     arrays/hashes of them (blessed plain structures included) cross; an unshareable result (a CODE ref, a
    #     resource) becomes the Future's error instead. A die() in the closure likewise lands on the Future as its
    #     error.
    #   * no scheduler objects - the closure must not call back into Acme::Parataxis APIs (spawn_blocking or any
    #     blocking await) while it runs; the worker's interpreter is a copy and its scheduler state is read-only.
    #
    # The returned Future composes with await / with_timeout / with_cancel / wait_all exactly like any other, because
    # the harvest is a plain scheduler fiber resolving an Acme::Parataxis::Future. Cancelling the *await* does not
    # stop the closure (a real OS thread cannot be yanked); it only withdraws the waiter, and the slot is released
    # when the closure actually finishes. Wall-clock only: spawn_blocking croaks inside run(virtual => 1), since real
    # OS work cannot be fast-forwarded by the mock clock.
    sub spawn_blocking {
        my $o    = _arg_offset( $_[0] );
        my $code = $_[$o];
        my @args = @_[ $o + 1 .. $#_ ];
        @_ = ();
        croak 'spawn_blocking() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'spawn_blocking() requires a Perl built with thread support (useithreads)'
            unless defined $Config{useithreads} && $Config{useithreads} eq 'define';
        croak 'spawn_blocking() must be called from inside a scheduled fiber (inside run())' if Acme::Parataxis->current_fid < 0;
        croak 'spawn_blocking() is wall-clock only and cannot be driven by the mock clock of run(virtual => 1)'
            if defined Acme::Parataxis->virtual_now;
        state $loaded = do {
            require threads;
            require threads::shared;
            require Thread::Queue;
            1;
        };
        $SB_PERMITS //= Acme::Parataxis::Semaphore->new( count => $SB_MAX );
        my $fut = Acme::Parataxis::Future->new;
        my $q   = Thread::Queue->new;
        $SB_PERMITS->down('spawn_blocking capacity');
        my $thr = eval {
            threads->create(

                # The worker's whole world is the closure: run it, marshall the return value (or capture a die() as the
                # error) with shared_clone, and push one payload back. Anything unshareable fails the eval and comes
                # back as the error, never a crash in the caller.
                sub {
                    my ( $c, $a, $oq ) = @_;
                    my $payload = eval { [ 1, threads::shared::shared_clone( $c->(@$a) ), undef ] };
                    $payload = [ 0, undef, threads::shared::shared_clone($@) ] unless $payload;
                    $oq->enqueue($payload);
                    1;
                },
                $code,
                \@args,
                $q,
            );
        };
        if ( !$thr ) {
            my $err = $@ || 'thread creation failed';
            $SB_PERMITS->up;
            $fut->set_error($err);
            return $fut;
        }

        # The harvester keeps the run loop awake with a 1ms poll sleep (await_sleep rides the matching wall-clock path
        # - loop timers when a driver is attached, the worker poll otherwise - and the loop therefore never idles or
        # false-deadlocks while an interpreter is out), then reaps the payload, resolves the Future and hands the
        # capacity slot to the next waiting spawn_blocking caller. Independent of the caller's cancellation scopes, so
        # an abandoned await never strands a slot beyond the closure's own runtime. The payload is enqueued as the
        # worker's last act, so reaping it with $thr->join (instead of detach) returns immediately AND retires the
        # interpreter before global destruction - a detached thread still registered at exit trips threads.pm's
        # "Can't undef active subroutine during global destruction" on some builds and corrupts the exit status.
        eval {
            fiber {
                while ( $q->pending == 0 ) { await_sleep(1) }
                my $payload = $q->dequeue_nb;    # the one queued item: the [ok, result, error] payload
                $thr->join;
                $SB_PERMITS->up;
                if   ( $payload->[0] ) { $fut->set_result( $payload->[1] ) }
                else                   { $fut->set_error( $payload->[2] ) }
                1;
            };
            1;
        } or
            do {
            my $err = $@;
            $thr->join;
            $SB_PERMITS->up;
            $fut->set_error($err);
            };
        return $fut;
    }

    # Run a CPU-bound closure in a forked child process and return its result as a normal Future.
    #
    # This is the same promise spawn_blocking makes, for a perl with no thread support. It is a separate entry point
    # rather than a backend switch inside spawn_blocking on purpose: the two have genuinely different limits, and a
    # caller should be able to see them at the call site instead of inheriting a silent per-build difference.
    #
    #   * no threads at all - the point. Nothing here requires threads, threads::shared or Thread::Queue, so a plain
    #     perl gets CPU offload and keeps the property that loading this distribution acquires no threads association.
    #   * copy-in by fork, copy-out by Storable - the child starts as a copy of the whole parent address space, so the
    #     closure sees the caller's world as it was at the fork: its args, and whatever its captured lexicals held
    #     then. Nothing the child does to memory comes back; the only thing that travels is the frozen result. A
    #     result Storable cannot store (a CODE ref, a resource) becomes the Future's error, as does a die().
    #   * the closure must not call back into Acme::Parataxis - the child's interpreter is a copy whose scheduler state
    #     is meaningless, and it holds copies of the parent's descriptors (including any attached driver's sockets), so
    #     a closure that reads or writes through one of those would act on a copy of a descriptor, not the original.
    #     Inherited descriptors also keep their ports busy until the child exits, which is worth knowing when a closure
    #     is short but a run is long.
    #   * cancellation kills - unlike the thread pool, this one can actually stop the work. Cancelling the *await*
    #     still only withdraws the waiter, exactly as with spawn_blocking, so nothing changes by accident; when you do
    #     want the work to stop, call kill_blocking_fork($future) and the child is signalled (TERM by default).
    #   * a harvester fiber always runs - it is scheduled independently of whether anyone awaits the Future, so the
    #     pipe is drained and the child reaped even if the caller never looks at the result. That is also what keeps a
    #     large result from deadlocking: a closure whose payload exceeds the pipe buffer blocks in write until the
    #     harvester's next chunk, which is the design working, not a hang.
    #   * wall-clock only, like spawn_blocking: real processes cannot be fast-forwarded, so this croaks under
    #     run( virtual => 1 ).
    sub spawn_blocking_fork {
        my $o    = _arg_offset( $_[0] );
        my $code = $_[$o];
        my @args = @_[ $o + 1 .. $#_ ];
        @_ = ();
        croak 'spawn_blocking_fork() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'spawn_blocking_fork() is not available on this platform (no fork(2); d_fork is ' .
            ( defined $Config{d_fork} ? $Config{d_fork} : 'undef' ) . ')'
            unless $Config{d_fork} && $Config{d_fork} eq 'define';
        croak 'spawn_blocking_fork() is not available on MSWin32, where perl\'s fork() is a threads.pm emulation' if $^O eq 'MSWin32';
        croak 'spawn_blocking_fork() must be called from inside a scheduled fiber (inside run())'                 if Acme::Parataxis->current_fid < 0;
        croak 'spawn_blocking_fork() is wall-clock only and cannot be driven by the mock clock of run(virtual => 1)'
            if defined Acme::Parataxis->virtual_now;
        state $have_marshal = do { require POSIX; require Storable; 1 };
        my $fut = Acme::Parataxis::Future->new;
        pipe( my $rd, my $wr ) or do {
            $fut->set_error("spawn_blocking_fork() could not create a pipe: $!");
            return $fut;
        };
        $SBF_PERMITS //= Acme::Parataxis::Semaphore->new( count => $SBF_MAX );
        $SBF_PERMITS->down('spawn_blocking_fork capacity');

        # The fork itself. The child shares nothing with the parent but this pipe, and it must leave through
        # POSIX::_exit rather than exit: a normal exit would run END blocks and global destruction over a heap it only
        # borrowed, letting the child's destructors touch a copy of the parent's objects. _exit also means the child's
        # copy of the parent's buffered STDOUT is never flushed a second time.
        my $pid = CORE::fork();
        if ( !defined $pid ) {
            my $err = "spawn_blocking_fork() could not fork: $!";
            close $rd;
            close $wr;
            $SBF_PERMITS->up;
            $fut->set_error($err);
            return $fut;
        }
        if ( !$pid ) {    # child
            close $rd;

            # One tagged frame on the wire: a 1-byte tag, then a length-prefixed body. The tag is what tells the
            # parent which of three things it is looking at, so the body is always a single string and exactly one
            # length is ever transmitted - framing an array by its element count instead of its byte count is the
            # kind of mistake that only shows up as a mystifying "Storable binary image v24.4 more recent than I am".
            my ( $tag, $body );
            my $image = eval { Storable::freeze( [ 1, $code->(@args) ] ) };
            if ( defined $image ) { ( $tag, $body ) = ( 'R', $image ) }
            else {
                my $err   = $@;
                my $image = eval { Storable::freeze( [ 0, "$err" ] ) };
                if ( defined $image ) { ( $tag, $body ) = ( 'E', $image ) }

                # Even the error string would not freeze. Say so in plain text rather than dying in silence.
                else { ( $tag, $body ) = ( 'X', "the closure failed and its error could not be marshalled: $err" ) }
            }
            my $frame = $tag . pack( 'Q>', length $body ) . $body;
            while ( length $frame ) {
                my $n = syswrite( $wr, $frame );
                last if !defined($n) || $n == 0;    # the parent is gone; there is nothing left to report to
                substr( $frame, 0, $n, '' );
            }
            close $wr;
            POSIX::_exit(0);
        }

        # parent: its own copy of the write end would keep the read end from ever seeing EOF
        close $wr;
        $SBF_CHILDREN{ builtin::refaddr($fut) } = $pid;

        # The permit is released exactly once. The body below runs in its own fiber, so the eval only ever catches a
        # fiber that could not be created at all - in which case the body never ran and its up never happened.
        eval {
            fiber {
                my $header = _fork_read_exactly( $rd, 9, 5000 );    # 1 tag byte + an 8-byte length
                my $tag    = length($header)      ? substr( $header, 0, 1 )               : '';
                my $len    = length($header) == 9 ? unpack( 'Q>', substr( $header, 1 ) )  : 0;
                my $body   = $len                 ? _fork_read_exactly( $rd, $len, 5000 ) : '';
                close $rd;
                my ( $reaped, $status, $sig ) = _fork_reap($pid);
                delete $SBF_CHILDREN{ builtin::refaddr($fut) };
                $SBF_PERMITS->up;

                if ( length($header) != 9 || length($body) != $len ) {
                    $fut->set_error(
                        "the forked child never delivered a result (" . (
                            !$reaped ? 'its status is unknown, it may already have been reaped elsewhere' :
                                $sig ? "it died on signal $sig" :
                                sprintf( 'it exited with status %d', $status )
                            ) .
                            ')'
                    );
                }
                elsif ( $tag eq 'X' ) { $fut->set_error($body) }
                else {
                    my $thawed = eval { Storable::thaw($body) };
                    if ( !defined $thawed || ref($thawed) ne 'ARRAY' ) {
                        $fut->set_error( "the forked child's result could not be read back: " . ( $@ || 'the thawed payload was not an array ref' ) );
                    }
                    elsif ( $thawed->[0] ) { $fut->set_result( $thawed->[1] ) }
                    else                   { $fut->set_error( $thawed->[1] ) }
                }
                1;
            };
            1;
        } or
            do {
            my $err = $@;
            close $rd;
            kill 'KILL', $pid;
            _fork_reap($pid);
            delete $SBF_CHILDREN{ builtin::refaddr($fut) };
            $SBF_PERMITS->up;
            $fut->set_error($err);
            };
        return $fut;
    }

    # Signal a running spawn_blocking_fork child. Returns true if a signal was delivered, false if the child was
    # already gone. Deliberately takes the Future rather than a pid: the caller holds a Future, and a pid it would have
    # to be told separately is a pid it can get wrong.
    sub kill_blocking_fork {
        my $o = _arg_offset( $_[0] );
        my ( $fut, $sig ) = @_[ $o, $o + 1 ];
        @_ = ();
        croak 'kill_blocking_fork() requires an Acme::Parataxis::Future'
            unless defined $fut && builtin::blessed($fut) && $fut->isa('Acme::Parataxis::Future');
        $sig = 'TERM' unless defined $sig;
        my $pid = $SBF_CHILDREN{ builtin::refaddr($fut) };
        return false if !defined $pid;
        return kill $sig, $pid;
    }

    # Raise (or lower) the spawn_blocking_fork concurrency cap. Only meaningful before the pool has been used, and
    # separate from the thread cap because a forked child and a cloned interpreter are not the same resource.
    sub set_max_blocking_forks {
        my $o   = _arg_offset( $_[0] );
        my $max = $_[$o];
        @_ = ();
        croak 'set_max_blocking_forks() requires a positive integer' unless defined $max && $max =~ /\A[1-9][0-9]*\z/;
        croak 'set_max_blocking_forks() must be called before the first spawn_blocking_fork() (the process pool is ' . 'already in use)'
            if $SBF_PERMITS;
        $SBF_MAX = int($max);
        return $SBF_MAX;
    }

    # The configured spawn_blocking_fork capacity (the default 4, PARATAXIS_SBF_FORKS, or set_max_blocking_forks).
    sub max_blocking_forks () {$SBF_MAX}

    # Raise (or lower) the spawn_blocking concurrency cap. Only meaningful before the pool has been used - once a
    # Semaphore exists its capacity is live and this croaks rather than silently stealing slots from in-flight
    # closures. Mirrors set_max_threads() for the C pool.
    sub set_max_blocking_threads {
        my $o   = _arg_offset( $_[0] );
        my $max = $_[$o];
        @_ = ();
        croak 'set_max_blocking_threads() requires a positive integer' unless defined $max && $max =~ /\A[1-9][0-9]*\z/;
        croak 'set_max_blocking_threads() must be called before the first spawn_blocking() (the interpreter pool is already in use)' if $SB_PERMITS;
        $SB_MAX = int($max);
        return $SB_MAX;
    }

    # The configured spawn_blocking capacity (the default 4, PARATAXIS_SB_THREADS, or set_max_blocking_threads).
    sub max_blocking_threads () {$SB_MAX}
};
#
1;
