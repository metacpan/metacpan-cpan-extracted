use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use experimental qw[class try];

package Acme::Parataxis v0.1.3 {
    use Affix;
    use Config;
    use File::Spec;
    use File::Basename qw[dirname];
    use Time::HiRes    qw[usleep];
    use Exporter       qw[import];
    use Carp           qw[croak];
    use builtin        qw[refaddr];
    use Acme::Parataxis::Error;
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                run spawn yield await stop async fiber
                await_sleep await_read await_write await_core_id
                current_fid tid root maybe_yield on_wake with_timeout with_cancel nursery pmap wait_all wait_any
                set_max_threads max_threads set_max_fibers max_fibers dump_fibers fd_setsize
                backtrace_depth
                atomically retry
                set_preempt_threshold
                ]
        ]
    );
    #
    our @IPC_BUFFER;
    my $lib;
    my @SCHEDULER_QUEUE;
    my %SCHEDULER_QUEUED;
    my $IS_RUNNING = 0;
    my $DRIVER;                 # the attached Acme::Parataxis::Driver (undef = the worker-pool fallback path), see attach_loop
    my %PARKED;                 # fid => true, while the fiber is suspended in a blocking wait (see _park / _resume_hooks)
    my %PARK_REGS;              # fid => coderef that removes a parked fiber from its waiter list when its park is interrupted
    our %FIBER_LOCALS;          # fiber-object refaddr => { local-id => value }; stashes for Acme::Parataxis::Local
    our @INHERIT_LOCAL_IDS;     # ids of Acme::Parataxis::Local objects created with inherit => 1; spawn seeds these from parent to child
    our %ACTOR_REGISTRY;        # registered actor names => Acme::Parataxis::Actor handles; the actor(name)/whereis table
    my $BACKTRACE_DEPTH = 6;    # max user-side caller frames captured at each park (0 disables the capture)
    my $VIRTUAL_CLOCK;          # undef = wall clock; a running virtual run sets this to the current virtual ms
    my %VIRTUAL_DEADLINES;      # fid => absolute virtual-ms deadline of that fiber's one armed virtual timer
    my @VIRTUAL_TIMERS;         # [deadline_ms, fid] ascending; lazy deletion via %VIRTUAL_DEADLINES

    # Fiber object layout: a flat arrayref of slots rather than perlclass objects (array access is much cheaper than
    # classes and even hash lookup on the hot spawn/await path).
    use constant {
        F_CODE            => 0,
        F_IS_DONE         => 1,
        F_ERROR           => 2,
        F_RESULT          => 3,
        F_FID             => 4,
        F_IS_READY        => 5,
        F_CALLBACKS       => 6,
        F_WAITER          => 7,
        F_LAST_STATUS     => 8,
        F_PRIORITY        => 9,
        F_WAIT_REASON     => 10,
        F_WAKE_HOOKS      => 11,
        F_INTERRUPT       => 12,
        F_CANCEL_SCOPES   => 13,
        F_DEADLINE_SCOPES => 14,
        F_DEADLINE_ARMED  => 15
    };

    # Scheduler run queue. Kept sorted by descending priority (stable for equal priorities, so a group of same-priority fibers stays FIFO).
    sub _enqueue ($fiber) {
        my $fid = $fiber->[F_FID];
        return if $SCHEDULER_QUEUED{$fid};
        $SCHEDULER_QUEUED{$fid} = 1;
        my $prio = $fiber->[F_PRIORITY] // 0;
        my $i    = 0;
        $i++ while $i < @SCHEDULER_QUEUE && ( $SCHEDULER_QUEUE[$i]->[F_PRIORITY] // 0 ) >= $prio;
        splice @SCHEDULER_QUEUE, $i, 0, $fiber;
    }

    # All C fiber ids that are currently live. Used by run() to snapshot the fibers that predate a run so its
    # deadlock detector only considers fibers the run actually created (fibers leaked by a prior deadlocked run stay
    # parked forever and would otherwise poison every later run).
    sub _live_fiber_ids () {
        my @ids;
        my $cap = Acme::Parataxis::get_fiber_capacity();
        for ( my $fid = 0; $fid < $cap; $fid++ ) {
            my $obj = Acme::Parataxis::get_fiber_by_id($fid);
            push @ids, $fid if defined $obj && ( ref $obj || '' ) ne '';
        }
        return @ids;
    }

    # Diagnostics: a snapshot of every live fiber, riding entirely on wait_reason: _park records
    # [reason, file, line] on the fiber before it yields and _resume_hooks clears it on a natural wake, so a
    # live fiber that still carries a reason (or is in %PARKED) is blocked, not merely preempted. WAITING =
    # parked on a wait; READY = in the scheduler run queue; RUNNING = the fiber calling the snapshot (only
    # when taken from inside a run); RUNNABLE = live but neither parked nor queued (e.g. a generator's body
    # or a fiber surrendered mid-quantum). Each record also carries the bounded user-side caller
    # chain (its fourth element) captured at the park; the top site is still the wait_reason site (the user's
    # call for direct waits like await_sleep, the wait's own method for Sync/Channel waits whose level
    # targeting is tuned for their error messages).
    sub _fiber_snapshot () {
        my $current = get_current_parataxis_id();
        my @rows;
        for my $fid ( _live_fiber_ids() ) {
            my $fiber = Acme::Parataxis::get_fiber_by_id($fid);
            next unless $fiber && ref $fiber;
            my $reason = $fiber->[F_WAIT_REASON];    # undef once the fiber is woken normally
            my $state
                = ( defined $reason || $PARKED{$fid} ) ? 'WAITING' :
                $SCHEDULER_QUEUED{$fid}                ? 'READY' :
                ( $current >= 0 && $fid == $current )  ? 'RUNNING' :
                'RUNNABLE';
            push @rows, { fid => $fid, state => $state, reason => $reason };
        }
        return [ sort { $a->{fid} <=> $b->{fid} } @rows ];
    }

    # Dumps every live fiber. Returns the arrayref of { fid, state, reason (wait_reason site; its fourth element is
    # the backtrace arrayref of [pkg, file, line, sub] user-side frames, [] when the capture is off or empty) }
    # records and, when called with a filehandle, also prints a human-readable report there (dump_fibers() with no
    # argument only returns the data). Safe to call from anywhere: top-level (outside a run) reports fibers leaked by
    # an earlier deadlocked run, inside a run it classifies each live fiber exactly.
    sub dump_fibers {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
            $invocant = __PACKAGE__;
        }
        my $fh   = shift;
        my $rows = _fiber_snapshot();
        return $rows unless $fh;
        say $fh 'Acme::Parataxis live fiber dump';
        say $fh '  fid   state    wait reason       where';
        for my $r (@$rows) {
            my ( $file, $line ) = $r->{reason} ? @{ $r->{reason} }[ 1, 2 ] : ( '-', '-' );
            say $fh sprintf '  %-4d %-8s %-17s %s:%s', $r->{fid}, $r->{state}, ( $r->{reason} && $r->{reason}[0] ) // '-', $file, $line;
            for my $bt ( @{ $r->{reason}[3] // [] } ) {
                say $fh sprintf '        at %s:%d  %s', @$bt[ 1, 2, 3 ];
            }
        }
        return $rows;
    }

    sub _bind_functions ($l) {
        affix $l, 'init_system',                                           [],                             Int;
        affix $l, 'create_fiber',                                          [ Pointer [SV], Pointer [SV] ], Int;
        affix $l, 'spawn_fiber',                                           [ Pointer [SV], Pointer [SV] ], Pointer [SV];
        affix $l, 'coro_call',                                             [ Int, Pointer [SV] ],          Pointer [SV];
        affix $l, 'run_fiber_checked',                                     [ Int, Pointer [SV] ],          Int;
        affix $l, 'coro_transfer',                                         [ Int, Pointer [SV] ],          Pointer [SV];
        affix $l, 'coro_yield',                                            [ Pointer [SV] ],               Pointer [SV];
        affix $l, 'is_finished',                                           [Int],                          Int;
        affix $l, 'get_fiber_by_id',                                       [Int],                          Pointer [SV];
        affix $l, 'get_live_fiber_count',                                  [],                             Int;
        affix $l, 'get_fiber_capacity',                                    [],                             Int;
        affix $l, 'destroy_coro',                                          [Int],                          Void;
        affix $l, 'para_release_cv_depth',                                 [ Pointer [SV] ],               Void;
        affix $l, 'para_cvreg_purge_fiber',                                [Int],                          Void;
        affix $l, 'force_depth_zero',                                      [ Pointer [SV] ],               Void;
        affix $l, 'cleanup',                                               [],                             Void;
        affix $l, 'get_os_thread_id_export',                               [],                             Int;
        affix $l, 'get_current_parataxis_id',                              [],                             Int;
        affix $l, 'submit_c_job',                                          [ Int, LongLong, Int ],         Int;
        affix $l, 'drain_jobs',                                            [ Pointer [SV] ],               Void;
        affix $l, 'check_for_completion',                                  [],                             Int;
        affix $l, 'get_outstanding_jobs',                                  [],                             Int;
        affix $l, 'recall_sleep_jobs_for_fiber',                           [Int],                          Int;
        affix $l, 'get_job_result',                                        [Int],                          Pointer [SV];
        affix $l, 'get_job_coro_id',                                       [Int],                          Int;
        affix $l, 'free_job_slot',                                         [Int],                          Void;
        affix $l, 'get_thread_pool_size',                                  [],                             Int;
        affix $l, 'get_max_thread_pool_size',                              [],                             Int;
        affix $l, 'get_fd_setsize',                                        [],                             Int;
        affix $l, 'set_max_threads',                                       [Int],                          Void;
        affix $l, 'get_max_fibers',                                        [],                             Int;
        affix $l, 'set_max_fibers',                                        [Int],                          Void;
        affix $l, [ 'set_preempt_threshold' => '_set_preempt_threshold' ], [LongLong],                     Void;
        affix $l, [ 'maybe_yield' => '_maybe_yield' ],                     [],                             Pointer [SV];
        affix $l, 'get_preempt_count',                                     [],                             LongLong;

        # Capture the main interpreter context
        init_system();
        if ( $^O eq 'MSWin32' ) {
            my $perl_dll = $Config{libperl};
            $perl_dll =~ s/^lib//;
            $perl_dll =~ s/\.a$//;
            $perl_dll .= '.' . $Config{so};
            my $p = Affix::load_library($perl_dll);
            affix $p, 'win32_get_osfhandle', [Int], LongLong;
        }
    }

    BEGIN {
        my $lib_name = ( $^O eq 'MSWin32' ? '' : 'lib' ) . 'parataxis.' . $Config{so};
        my @paths;
        push @paths, File::Spec->catfile( dirname(__FILE__), $lib_name );
        push @paths, File::Spec->catfile( dirname(__FILE__), '..',   'arch', 'auto',      'Acme', 'Parataxis', $lib_name );
        push @paths, File::Spec->catfile( dirname(__FILE__), '..',   '..',   'arch',      'auto', 'Acme', 'Parataxis', $lib_name );
        push @paths, File::Spec->catfile( dirname(__FILE__), 'auto', 'Acme', 'Parataxis', $lib_name );
        for my $inc (@INC) {
            next if ref $inc;
            push @paths, File::Spec->catfile( $inc, 'auto', 'Acme', 'Parataxis', $lib_name );
        }
        for my $path (@paths) {
            if ( -e $path ) {
                $lib = Affix::load_library($path);
                last if $lib;
            }
        }
        die 'Could not find or load ' . $lib_name unless $lib;
        _bind_functions($lib);
    }

    # API aliases and wrappers
    sub fiber : prototype(&) ($code) { spawn( __PACKAGE__, $code ) }
    sub async : prototype(&) ($code) { return run($code) }

    # Index at which user arguments start in @_: 0 when it is a plain call, 1 when $_[0] is a self (package name or
    # blessed object). This mirrors the shift/unshift invocant dance used elsewhere, but reads $_[0] instead of
    # shifting, so calling it never reifies the caller's pad @_. A reified @_ left behind in a parked frame trips
    # pp_entersub's assert(!AvREAL(av))/assert(AvFILLp(av) == -1) when a different fiber later enters the same sub at
    # the same depth.
    sub _arg_offset {
        my $self = $_[0];
        return ( defined $self && ( ( ref $self || $self ) eq __PACKAGE__ || ( builtin::blessed($self) && $self->isa(__PACKAGE__) ) ) ) ? 1 : 0;
    }

    # Aggregate a list of futures into one that resolves when every input has: the result is an arrayref of each
    # input's result, in input order, or the stored error of the first input to fail (reject-fast, Promise.all style).
    # Inputs are not cancelled on a rejection; they are independent and keep running, and their later results are
    # discarded. Zero futures resolve immediately with [] (matching Promise.all([])). An already-resolved input
    # fires its on_ready callback inline, so a wait_all of ready inputs resolves inline (no fiber needed) and any
    # mixed ready/pending input resolves the moment the last straggler lands. Inputs must be Acme::Parataxis::Future
    # objects else croaks. Also callable as Acme::Parataxis->wait_all(...).
    sub wait_all {
        my $o       = _arg_offset( $_[0] );
        my @futures = @_[ $o .. $#_ ];
        @_ = ();
        croak 'wait_all() requires Acme::Parataxis::Future inputs'
            if grep { !( defined $_ && ref $_ && $_->isa('Acme::Parataxis::Future') ) } @futures;
        require Acme::Parataxis::Future;
        my $all = Acme::Parataxis::Future->new;
        if ( @futures == 0 ) {
            $all->set_result( [] );
            return $all;
        }
        my @results;
        my $pending = scalar @futures;
        for my $i ( 0 .. $#futures ) {
            my $idx = $i;
            my $fut = $futures[$i];
            $fut->on_ready(
                sub ($f) {
                    return if $all->is_ready;
                    if ( defined $f->error ) {
                        $all->set_error( $f->error );    # reject-fast: the first failure wins, copied wholesale
                        return;
                    }
                    $results[$idx] = $f->result;
                    $all->set_result( \@results ) if --$pending == 0;
                }
            );
        }
        return $all;
    }

    # Aggregate a list of futures into one that settles with a wholesale copy of the first input to settle - success
    # or failure (Promise.race). The losers are untouched and keep running; their eventual results are dropped by the
    # is_ready guard. An already-ready input settles the aggregate inline. At least one input is required (an empty
    # race would never settle) and each input must be an Acme::Parataxis::Future else croaks. Also callable as
    # Acme::Parataxis->wait_any(...).
    sub wait_any {
        my $o       = _arg_offset( $_[0] );
        my @futures = @_[ $o .. $#_ ];
        @_ = ();
        croak 'wait_any() requires at least one Acme::Parataxis::Future input' unless @futures;
        croak 'wait_any() requires Acme::Parataxis::Future inputs'
            if grep { !( defined $_ && ref $_ && $_->isa('Acme::Parataxis::Future') ) } @futures;
        require Acme::Parataxis::Future;
        my $any = Acme::Parataxis::Future->new;
        for my $f (@futures) {
            $f->on_ready(
                sub ($f) {
                    return if $any->is_ready;
                    if   ( defined $f->error ) { $any->set_error( $f->error ) }     # wholesale copy of the failure
                    else                       { $any->set_result( $f->result ) }
                }
            );
        }
        return $any;
    }

    sub yield {
        my $is_self = _arg_offset( $_[0] );
        my @deposit = ();
        push @deposit, $_[$_] for ( $is_self ? 1 : 0 ) .. $#_;
        if ( !$is_self && @deposit && !defined $deposit[0] ) {
            shift @deposit;
        }
        @_ = ();
        my $result = coro_yield( \@deposit );
        return unless defined $result;
        return ( ref $result eq 'ARRAY' ) ? ( wantarray ? @$result : $result->[-1] ) : $result;
    }

    # Park the current fiber in a blocking wait, recording why and where (for diagnostics and cancellation).
    # $level is the caller stack depth (relative to _park) of the *user* frame whose location should be attributed:
    # 1 for direct wait sites, 2 for a Semaphore down(), 3 for a Channel get()/put().
    #
    # The wait-reason record is [reason, file, line] plus a fourth element, a bounded backtrace of the
    # user-side callchain (caller frames from just below the recorded site back to the fiber body). Capturing it
    # is a short caller() loop (~100ns per frame), so it runs unconditionally; backtrace_depth(0) disables it.
    # On the *re-entry* after the yield returns, a pending interrupt (set by _interrupt) is consumed and thrown, so a
    # cancelled wait unwinds with Acme::Parataxis::Error::Cancelled (or ::Timeout) right here the caller of the wait
    # sees the parked wait's own reason in the error's wait_reason.
    #
    # $dereg, when given, is a coderef that removes the *parking* fiber from whatever waiter list it is parked on
    # (Semaphore/Signal/Future/child-await). It runs only when this park is interrupted, before the error is thrown, so
    # a cancelled fiber never leaves a stale id behind that a later wake could fire at a reused fiber.
    sub backtrace_depth {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
            $invocant = __PACKAGE__;
        }
        return $BACKTRACE_DEPTH unless @_;
        my ($depth) = @_;
        croak 'backtrace_depth must be a non-negative integer' if !defined $depth || $depth !~ /^\d+$/;
        $BACKTRACE_DEPTH = $depth;
        return $BACKTRACE_DEPTH;
    }

    sub _park ( $reason, $level = 1, $dereg = undef, $nodl = 0 ) {
        my $fid = Acme::Parataxis->current_fid;
        croak '_park() must be called from inside a scheduled fiber' if $fid < 0;
        my $fiber = Acme::Parataxis->by_id($fid);
        return unless $fiber;    # already finished; nothing to park

        # Fail fast: a fiber that was interrupted while it was running (not parked), then reached a wait point, throws
        # at the park entry instead of parking, so a cancellation never gets stranded until some unrelated wake. The
        # C job table may still have armed the sleep/read this wait was about to submit, so the run can stay alive
        # until those fire - but no wait is entered after its cancellation.
        if ( defined( my $pre = $fiber->[F_INTERRUPT] ) ) {
            my ( $pfile, $pline ) = ( caller($level) )[ 1, 2 ];
            my $pre_site = [ $pre, $pfile, $pline ];
            warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d ENTRY failfast pre=%s site=%s\n", ( time - $^T ) * 1000, $fid, $pre, "$pfile:$pline"
                if $ENV{PARATAXIS_TRACE};
            $fiber->[F_INTERRUPT] = undef;
            delete $PARKED{$fid};
            if ( my $dereg = delete $PARK_REGS{$fid} ) { $dereg->() }
            warn "PARATAXIS_TRACE park RE-ENTRY fail-fast fid=$fid reason=$reason pre=$pre\n" if $ENV{PARATAXIS_TRACE};
            my $err = $pre eq 'timeout' ? Acme::Parataxis::Error::Timeout->new( wait_reason => $pre_site ) :
                Acme::Parataxis::Error::Cancelled->new( wait_reason => $pre_site );
            die $err;
        }

        # A cancellation scope whose token already fired makes every further wait fail fast too: once the fiber's
        # pending marker has been consumed (a park threw Error::Cancelled and the user caught it), a re-park inside
        # the still-active scope must not wait in vain. Same shape as the entry fail-fast above, but keyed off the
        # innermost scope token's own cancelled flag instead of the fiber's interrupt slot.
        if ( my $scopes = $fiber->[F_CANCEL_SCOPES] ) {
            my $scope = $scopes->[-1];
            if ( $scope && $scope->cancelled ) {
                my ( $pfile, $pline ) = ( caller($level) )[ 1, 2 ];
                delete $PARKED{$fid};
                if ( my $old = delete $PARK_REGS{$fid} ) { $old->() }
                $dereg->() if $dereg;    # this park's waiter entry (pushed before _park) is stale: remove it too
                die Acme::Parataxis::Error::Cancelled->new( wait_reason => [ 'cancel', $pfile, $pline ] );
            }
        }

        # Enclosing with_timeout deadlines bound this park. Every with_timeout whose execution this fiber is
        # inside pushed an absolute deadline (in ms) onto F_DEADLINE_SCOPES; the innermost/soonest one wins as the
        # effective bound and the outermost is the backstop. Three consequences, in order:
        #   (a) an already-passed effective bound makes a fresh wait fail fast with Error::Timeout instead of parking
        #       forever - without this, a caught Timeout followed by a re-park under the same fired deadline deadlocked
        #       (nothing was left to interrupt the wait); the check is the bound's own cancellable token being set, not
        #       just the arithmetic (left <= 0), because the deadline helper's timer may fire marginally before the wall
        #       clock reaches abs - a re-park landing in that window would otherwise be missed by the arithmetic and
        #       (since the bound is armed already) would park with nothing left to interrupt it;
        #   (b) exactly one deadline helper is armed per fiber for its effective bound and reused across re-parks
        #       (F_DEADLINE_ARMED), so a re-park never stacks a second timer for the same bound; the helper cancels the
        #       bound's token, which interrupts the registered fiber via the usual _interrupt path and recalls its jobs;
        #   (c) a helper is only armed for a bound the fiber itself owns (own => 1). An *inherited* bound (an enclosing
        #       ancestor's with_timeout, whose token this fiber is not registered on) is always enforced by that
        #       ancestor's own await-park, so arming it here would be redundant - though its absolute deadline still
        #       participates in (a), so an inherited scope whose time has already come fails fast too.
        # $nodl (now the reap re-park and other transient non-user waits) opts out: a wait whose only job is to reap a
        # dying child must not fail fast nor arm, since it must linger until the child's death is observed.
        if ( !$nodl && $fiber->[F_DEADLINE_SCOPES] ) {
            my $eff;
            for my $sc ( @{ $fiber->[F_DEADLINE_SCOPES] } ) {
                next unless defined $sc->{abs};
                $eff = $sc if !defined $eff || $sc->{abs} < $eff->{abs};
            }
            if ( defined $eff ) {
                my $now  = _now_ms();
                my $left = $eff->{abs} - $now;
                if ( $left <= 0 || $eff->{tok}->cancelled ) {
                    my ( $pfile, $pline ) = ( caller($level) )[ 1, 2 ];
                    delete $PARKED{$fid};
                    if ( my $old = delete $PARK_REGS{$fid} ) { $old->() }
                    $dereg->() if $dereg;    # as above: this park's own waiter entry is stale too
                    warn "PARATAXIS_TRACE park DEADLINE fail-fast fid=$fid reason=$reason abs=" . $eff->{abs} . " now=$now\n"
                        if $ENV{PARATAXIS_TRACE};
                    die Acme::Parataxis::Error::Timeout->new( wait_reason => [ 'timeout', $pfile, $pline ] );
                }
                if ( $eff->{own} ) {
                    my $already = $fiber->[F_DEADLINE_ARMED];
                    if ( defined $already && $already == $eff->{abs} ) {
                        warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d park DEADLINE reuse abs=%.0f (already armed)\n", ( time - $^T ) * 1000, $fid,
                            $eff->{abs}
                            if $ENV{PARATAXIS_TRACE};
                    }
                    else {
                        my $tok = $eff->{tok};
                        warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d park DEADLINE arm abs=%.0f left=%.0f was=%s\n", ( time - $^T ) * 1000, $fid,
                            $eff->{abs}, $left, defined $already ? $already : 'undef'
                            if $ENV{PARATAXIS_TRACE};
                        fiber {
                            $tok->register;
                            try { await_sleep($left); $tok->cancel } catch ($e) {
                            }
                        };
                        $fiber->[F_DEADLINE_ARMED] = $eff->{abs};
                    }
                }
            }
        }
        my ( $file, $line ) = ( caller($level) )[ 1, 2 ];
        my $bt = [];
        if ($BACKTRACE_DEPTH) {
            for ( my $i = 1; $i <= $BACKTRACE_DEPTH; $i++ ) {
                my @c = caller( $level + $i );
                last unless defined $c[0];
                next if index( $c[0], 'Acme::Parataxis' ) == 0;    # user-side frames only
                push @$bt, [ $c[0], $c[1], $c[2], $c[3] ];
            }
        }
        my $site = [ $reason, $file, $line, $bt ];
        $fiber->[F_WAIT_REASON] = $site;
        $PARKED{$fid}           = 1;
        $PARK_REGS{$fid}        = $dereg if defined $dereg;
        my $res = yield('WAITING');
        if ( defined( my $kind = $fiber->[F_INTERRUPT] ) ) {
            my $wsite = $fiber->[F_WAIT_REASON] // [ 'undef', 'undef', 'undef' ];
            warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d re-entry interrupt consumed kind=%s wait_reason=%s wait_site=%s park_site=%s\n",
                ( time - $^T ) * 1000, $fid, $kind, $wsite->[0] // 'undef', $wsite->[1] . ':' . $wsite->[2],
                ( defined $site ? $site->[1] . ':' . $site->[2] : 'n/a' )
                if $ENV{PARATAXIS_TRACE};
            $fiber->[F_INTERRUPT] = undef;
            delete $PARKED{$fid};
            if ( my $dereg = delete $PARK_REGS{$fid} ) { $dereg->() }
            my $err = $kind eq 'timeout' ? Acme::Parataxis::Error::Timeout->new( wait_reason => $site ) :
                Acme::Parataxis::Error::Cancelled->new( wait_reason => $site );
            die $err;
        }
        return $res;
    }

    # Marks a fiber as interrupted and, if it is currently parked, wakes it so the interrupt is observed at the park's
    # re-entry. A fiber that is not parked keeps the marker and the first park it (re)enters afterwards throws. $kind is
    # 'cancel' or 'timeout' and selects which error the fiber throws.
    sub _interrupt ( $fid, $kind ) {
        my $fiber = Acme::Parataxis->by_id($fid);
        return unless $fiber;
        return                        if $fiber->[F_IS_DONE];
        $fiber->[F_INTERRUPT] = $kind if $kind eq 'cancel' || $kind eq 'timeout';
        recall_sleep_jobs_for_fiber($fid);
        _recall_virtual_timer($fid);    # a virtual timer has no C job; drop it so a recalled fiber is never re-woken
        _scheduler_enqueue_by_id($fid) if $PARKED{$fid};
        return $fiber;
    }

    # On a natural wake the park's deregistrations are dropped (the park is over); on an interrupt wake they are kept
    # for the throw in _park, which runs them before the fiber unwinds.
    sub _resume_hooks ($fiber) {
        return unless delete $PARKED{ $fiber->[F_FID] };
        $fiber->[F_WAIT_REASON] = undef;
        delete $PARK_REGS{ $fiber->[F_FID] } unless defined $fiber->[F_INTERRUPT];
        my $hooks = $fiber->[F_WAKE_HOOKS];
        $fiber->[F_WAKE_HOOKS] = undef;
        if ($hooks) { $_->($fiber) for @$hooks }
    }

    # -- deterministic mock time. Inside run( virtual => 1, ... ) every timer-based wait (await_sleep,
    # -- with_timeout deadlines, Channel bounds, select, Ticker/RateLimiter) and every wall-clock read consulted
    # -- through the helpers below rides the virtual clock a test drives with advance(); outside such a run they all
    # -- fall back to the real wall clock, so real runs are untouched. A virtual run never submits a TASK_SLEEP job:
    # -- the armed virtual timer parks the fiber in-process and the scheduler idle path fast-forwards the clock to the
    # -- earliest outstanding deadline instead of sleeping, so an hour-long timeout costs microseconds.
    sub virtual_now {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        return $VIRTUAL_CLOCK;    # undef when not inside a virtual run, else current virtual ms
    }

    sub mock_time {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        return defined $VIRTUAL_CLOCK ? $VIRTUAL_CLOCK / 1000 : Time::HiRes::time();
    }
    sub _now_ms { return defined $VIRTUAL_CLOCK ? $VIRTUAL_CLOCK : Time::HiRes::time() * 1000 }

    # Arm a virtual-timer deadline for $fid, $ms from the current virtual clock. A fiber only ever parks in one
    # timer-backed wait at a time (a wait never returns until its wake), so one deadline per fiber suffices.
    sub _arm_virtual_timer ( $fid, $ms ) {
        return if $fid < 0;
        my $dl = $VIRTUAL_CLOCK + $ms;
        $VIRTUAL_DEADLINES{$fid} = $dl;
        push @VIRTUAL_TIMERS, [ $dl, $fid ];
        @VIRTUAL_TIMERS = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @VIRTUAL_TIMERS;
        return $dl;
    }

    # Drop a fiber's armed virtual timer (interrupt, completion, or fiber teardown). Lazy: the sorted array entry
    # stays until the next fire, where the deadline-hash mismatch skips it.
    sub _recall_virtual_timer ($fid) { delete $VIRTUAL_DEADLINES{$fid} }

    # Wake every fiber whose virtual deadline is at or before $now. Returns how many were actually woken (recalled
    # timers are popped and skipped, never woken).
    sub _fire_virtual ($now) {
        my $fired = 0;
        while ( @VIRTUAL_TIMERS && $VIRTUAL_TIMERS[0][0] <= $now ) {
            my ( $dl, $fid ) = @{ shift @VIRTUAL_TIMERS };
            next unless exists $VIRTUAL_DEADLINES{$fid} && $VIRTUAL_DEADLINES{$fid} == $dl;
            delete $VIRTUAL_DEADLINES{$fid};
            Acme::Parataxis::_scheduler_enqueue_by_id($fid);
            $fired++;
        }
        return $fired;
    }

    # The per-fiber stash behind Acme::Parataxis::Local, created lazily. Keyed by the fiber OBJECT (not its fid):
    # a spawned fiber that finishes inline has its fid recycled in C with no Perl-side completion hook, so a fid key
    # would survive into the recycled id and leak state into the next fiber. The object is the fiber's identity for
    # as long as it lives; entries are pruned where the object's fid is released (_mark_done, is_done) and on DESTROY.
    sub _fiber_locals ($fiber) { return $FIBER_LOCALS{ refaddr($fiber) } //= {} }

    sub on_wake {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
            $invocant = __PACKAGE__;
        }
        my $code = shift;
        croak 'on_wake() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        croak 'on_wake() requires a CODE ref' unless ref $code eq 'CODE';
        my $fiber = Acme::Parataxis->by_id( Acme::Parataxis->current_fid );
        push @{ $fiber->[F_WAKE_HOOKS] }, $code;
        return $code;
    }

    # Runs $code as a child fiber with a deadline of $ms milliseconds and returns its value, or throws
    # Acme::Parataxis::Error::Timeout when the deadline fires first. An optional Acme::Parataxis::CancellationToken
    # before $code cancels the block like an external deadline. A 0 or undef $ms means no deadline.
    #
    # The block runs as a child fiber in the same scheduler, so cooperative waits inside it (await_sleep, ->await,
    # ->wait, semaphore/signal/channel ops) suspend only the block's fiber. When a token fires, the child's parked wait
    # is interrupted at its park re-entry and the child unwinds (unregistering from the tokens as it goes);
    # with_timeout rethrows the resulting error (::Timeout or ::Cancelled) in this fiber, so it can be caught with
    # eval/try.
    #
    # The deadline is enforced per-park by _park from a per-fiber scope stack (F_DEADLINE_SCOPES). This
    # child pushes its bound onto that stack (inheriting the enclosing with_timeouts of the spawning fiber, so a
    # nested block's parks are bounded by the whole chain, innermost/soonest first and the outermost as the backstop)
    # and _park derives the effective bound, fails fast when it has already passed (a caught Timeout followed by a
    # re-park under the same fired deadline throws again instead of deadlocking), and arms exactly one deadline helper
    # per fiber for its bound - reused across re-parks, so no second timer is ever stacked for the same bound. When
    # the block finishes (or is itself interrupted) teardown's token cancel recalls the helper's armed sleep and the
    # worker is freed instead of staying occupied for the whole bound; no helper is armed at all when the block never
    # parks or when $ms is 0.
    sub with_timeout {
        my $o = _arg_offset( $_[0] );
        $o++ if $o == 0 && !defined $_[0];
        my $ms = $_[$o];
        croak 'with_timeout() requires a duration in milliseconds' unless defined $ms && $ms >= 0;
        my $tok;
        my $code;
        if ( ref $_[ $o + 1 ] eq 'Acme::Parataxis::CancellationToken' ) {
            $tok  = $_[ $o + 1 ];
            $code = $_[ $o + 2 ];
        }
        else {
            $code = $_[ $o + 1 ];
        }
        croak 'with_timeout() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'with_timeout() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        @_ = ();
        if ( $tok && $tok->cancelled ) {    # the user already cancelled: fail without running the block
            die Acme::Parataxis::Error::Cancelled->new;
        }
        state $have_token = do { require Acme::Parataxis::CancellationToken; 1; };
        my $deadline = Acme::Parataxis::CancellationToken->new( kind => 'timeout' );
        $tok = $deadline unless $tok;       # no explicit token: the deadline alone governs the block

        # The absolute (ms-clock) bound this block's parks must respect, and a shallow copy of the spawning fiber's
        # enclosing scopes to seed the child's stack with (marked as inherited so the child never arms a helper for a
        # token it is not registered on - the owning ancestor enforces those).
        my $scope_abs = $ms > 0 ? _now_ms() + $ms : undef;
        my $inherited = do {
            my $pfid = Acme::Parataxis->current_fid;
            my $pf   = $pfid >= 0                      ? Acme::Parataxis->by_id($pfid) : undef;
            my $stk  = $pf && $pf->[F_DEADLINE_SCOPES] ? $pf->[F_DEADLINE_SCOPES]      : undef;
            $stk ?
                [
                map {
                    { %$_, own => 0 }
                } @$stk
                ] :
                [];
        };
        my $child = fiber {
            my $cf = Acme::Parataxis->by_id( Acme::Parataxis->current_fid );
            $cf->[F_DEADLINE_SCOPES] = defined $scope_abs ? [ @$inherited, { abs => $scope_abs, tok => $deadline, own => 1 } ] : $inherited;
            $deadline->register;
            $tok->register if $tok ne $deadline;
            my $val;
            my $err;
            try { $val = $code->() } catch ($e) {
                $err = $e
            }
            $deadline->unregister;
            $tok->unregister                  if $tok ne $deadline;
            pop @{ $cf->[F_DEADLINE_SCOPES] } if defined $scope_abs;    # leave the stack for any enclosing scope
            die $err                          if $err;                  # the ::Timeout/::Cancelled throw (or any real error) unwinds out of the child
            return $val;
        };

        # The block finished synchronously: the value (or an inline error, already rethrown by spawn) is final. Skipping
        # the deadline also means a quick inlined block never pins its run.
        if ( $child->is_done ) {
            die $child->error if defined $child->error;
            return $child->result;
        }
        my $rv;
        my $ok = 1;
        my $err;
        try { $rv = $child->await } catch ($e) {
            $ok  = 0;
            $err = $e
        }
        warn "with_timeout teardown: ok=$ok child_done=" .
            $child->is_done .
            " child_error=" .
            ( defined $child->error ? ref( $child->error || '' ) || 'plain:' . $child->error : 'undef' ) .
            " deadline_cancelled=" .
            $deadline->cancelled .
            " deadline_waiters=" .
            $deadline->waiters .
            " tok_waiters=" .
            ( $tok->waiters // 'undef' ) . " err=" .
            ( ref( $err || '' ) || 'plain:' . $err ) . "\n"
            if $ENV{PARATAXIS_TRACE};

        # The child is final, so nothing else may keep waiting under these tokens. Even if *this* fiber was just
        # cancelled out from under the await (an enclosing nursery/with_timeout interrupted us, or a user token fired):
        # cancel the deadline now so a still-registered grandchild (a nested block, or the deadline helper _park armed
        # for our bound) is itself interrupted instead of outliving its parent and running to completion. The recall
        # now wakes the helper immediately, so its abandoned sleep job aborts in sub-millisecond time and no live work
        # continues past its parent.
        # A grandchild woken this way dies observer-gated (its parent's await had registered _wake_waiter on it), so it
        # unwinds silently rather than killing the run.
        $deadline->cancel;
        $tok->cancel if $tok ne $deadline;
        warn sprintf "with_timeout re-park branch: fid=%d child_done=%d err=%s\n", Acme::Parataxis->current_fid, $child->is_done,
            ref( $err || '' ) || 'plain:' . $err
            if $ENV{PARATAXIS_TRACE};
        if ( !$ok && !$child->is_done ) {

            # We were cancelled out of the await while the child is still parked. It is interrupted and will die on its
            # next resume. Re-park here, registered for the child's death, so the scheduler lets the child run its own
            # unwind (unregistering from its tokens and running destructors) and reaps it before this frame unwinds and
            # frees $child. Freeing the child mid-park no longer crashes (a C-level coroutine-lifecycle fix), so this
            # branch is no longer load-bearing for safety - it is kept so an abandoned child dies by unwinding rather
            # than being yanked. The interrupt marker on this fiber was consumed by the throwing await, so returning
            # from this park (rather than throwing again) is certain. $nodl is set: this is a transient reap wait, not
            # a user wait, so it must neither fail fast on an already-passed deadline nor arm a deadline helper.
            my $fid = Acme::Parataxis->current_fid;
            $child->on_ready( sub { Acme::Parataxis::_scheduler_enqueue_by_id($fid) } );
            Acme::Parataxis::_park( 'fiber await', 1, undef, 1 );
            $child->is_done;    # reap the coroutine now that its death has been observed
        }
        die $err unless $ok;
        return $rv;
    }

    # Runs $code as a cancellation *scope* on the current fiber: while the block is active, every wait it enters is
    # interruptible by one token - the scope token returned here - without the caller having to thread that token
    # into each primitive. Unlike with_timeout, no child fiber is spawned; the block runs on this fiber, so interior
    # awaits and parks suspend only the normal way. The token registers this fiber for the block's whole duration
    # (a register/unregister pair, not a per-park one), so an outer cancel() both interrupts a wait parked now and
    # stamps the fiber so the *next* wait entered inside the scope fails fast. Scopes stack LIFO in a per-fiber slot
    # (_park reads the innermost one); nesting with_timeout or nursery tokens shares the park, and whichever token
    # fires first ends the wait while teardown drops the others' registrations.
    #
    # Return convention (context aware): the scope token alone in scalar/void context, the token prepended to the
    # block's value(s) in list context (my ($tok, @vals) = with_cancel sub { ... }). On failure the block's own
    # error propagates unchanged (the real error wins over a concurrently arriving cancel); if the scope itself was
    # cancelled by an outer token while the block ran to completion, Error::Cancelled (or Timeout for a deadline)
    # is thrown at the scope boundary instead of swallowing the interrupt.
    sub with_cancel {
        my $o    = _arg_offset( $_[0] );
        my $code = $_[$o];
        @_ = ();
        croak 'with_cancel() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'with_cancel() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        state $have_token = do { require Acme::Parataxis::CancellationToken; 1 };
        my $tok   = Acme::Parataxis::CancellationToken->new( kind => 'cancel' );
        my $fiber = Acme::Parataxis->by_id( Acme::Parataxis->current_fid );
        push @{ $fiber->[F_CANCEL_SCOPES] }, $tok;
        $tok->register;    # block-wide: this fiber stays registered while the scope is open
        my @val;
        my $err;

        if (wantarray) {
            try { @val = $code->($tok) } catch ($e) {
                $err = $e
            }
        }
        else {
            try { $val[0] = $code->($tok) } catch ($e) {
                $err = $e
            }
        }
        $tok->unregister;
        pop @{ $fiber->[F_CANCEL_SCOPES] };
        if ($err) {

            # The block's own error wins: drop any interrupt still pending so it cannot resurface at an outer scope
            # after this one has already reported the real failure.
            $fiber->[F_INTERRUPT] = undef;
            die $err;
        }
        if ( my $kind = $fiber->[F_INTERRUPT] ) {

            # The block returned normally but an outer token/deadline fired while it ran: consume the marker and
            # convert it to the matching error so the cancellation is never silently swallowed at this boundary.
            $fiber->[F_INTERRUPT] = undef;
            die $kind eq 'timeout' ? Acme::Parataxis::Error::Timeout->new : Acme::Parataxis::Error::Cancelled->new;
        }
        return wantarray ? ( $tok, @val ) : $tok;
    }

    # STM (software transactional memory). atomically() runs $code as one transaction on the calling fiber: reads are
    # journaled, writes stay in a write set until the outermost atomically commits (validating
    # every read first, re-running on conflict), and retry() parks the fiber until a TVar it
    # read changes. The block may run many times - no irreversible side effects inside it.
    # See Acme::Parataxis::TVar for the semantics and the SIDE EFFECTS warning.
    sub atomically : prototype(&) {
        my $o    = _arg_offset( $_[0] );
        my $code = $_[$o];
        croak 'atomically() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'atomically() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        @_ = ();
        require Acme::Parataxis::TVar;
        return Acme::Parataxis::TVar::_atomically($code);
    }

    # STM. Aborts the enclosing atomically block and re-runs it once a TVar the
    # transaction has read changes; croaks anywhere else.
    sub retry {
        my $o = _arg_offset( $_[0] );
        croak 'retry() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        @_ = ();
        require Acme::Parataxis::TVar;
        Acme::Parataxis::TVar::_retry();
    }

    # Structured concurrency. $code runs in the calling fiber with an Acme::Parataxis::Nursery
    # as its argument; every child spawned through $n->spawn is guaranteed to finish before nursery()
    # returns, and the first child that dies cancels all of its siblings. Children never run inline
    # into the block (Nursery::spawn parks each at birth), so a child failure always surfaces through
    # the scheduler and is aggregated as Acme::Parataxis::Error::Nursery rather than thrown here.
    # If $code itself dies, its children are cancelled and drained before its error is rethrown.
    sub nursery {
        my $o = _arg_offset( $_[0] );
        $o++ if $o == 0 && !defined $_[0];
        my $code = $_[$o];
        croak 'nursery() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'nursery() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        @_ = ();
        state $have_nursery = do { require Acme::Parataxis::Nursery; 1 };
        my $nursery = Acme::Parataxis::Nursery->new;
        my $rv;
        my $ok = 1;
        my $err;
        try { $rv = $code->($nursery) } catch ($e) {
            $ok  = 0;
            $err = $e
        }

        # The block died: its children must not be orphaned, so cancel them and drain below.
        $nursery->token->cancel unless $ok;

        # All-children-join. A child failure has already cancelled the rest via the observer,
        # so the drain is fast; it unwinds every sibling before control returns to the parent.
        my @failures = $nursery->_join;
        die $err if !$ok;    # the block's own error wins over its children's
        if (@failures) {
            die Acme::Parataxis::Error::Nursery->new( failures => \@failures );
        }
        return $rv;
    }

    # Parallel map over a bounded fiber pool. $code runs once per item, each call in its own worker fiber (so a
    # mapper may await, park, or use any primitive), with at most $opts{concurrency} workers in flight at once
    # (default: one fiber per item). The caller parks while the pool works and the results come back in input order
    # even when items finish out of order. A mapper that dies cancels the pool (the sibling workers stop at their
    # next item boundary) and its error is rethrown once every worker has drained; later results are discarded.
    # Must be called from inside a scheduled fiber, like nursery; an empty item list returns immediately; the
    # concurrency option must be a positive integer.
    sub pmap {
        my $origin = _arg_offset( $_[0] );
        my %opts;
        my $i = $origin;
        if ( ref $_[$i] eq 'HASH' ) {
            %opts = %{ $_[ $i++ ] };
        }
        my $code  = $_[ $i++ ];
        my @items = @_[ $i .. $#_ ];
        @_ = ();
        croak 'pmap() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'pmap() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        return unless @items;
        my $concurrency = $opts{concurrency} // scalar @items;
        croak 'pmap() concurrency must be a positive integer' unless defined $concurrency && $concurrency =~ /\A[1-9]\d*\z/;
        $concurrency = @items if $concurrency > @items;
        require Acme::Parataxis::Channel;
        require Acme::Parataxis::Sync::WaitGroup;
        require Acme::Parataxis::CancellationToken;
        my $jobs = Acme::Parataxis::Channel->new( capacity => $concurrency );
        my $wg   = Acme::Parataxis::Sync::WaitGroup->new;
        my $tok  = Acme::Parataxis::CancellationToken->new;
        my ( @results, $first_error );

        # One unit for the feeder plus one per worker; the call parks below until they all land.
        $wg->add( $concurrency + 1 );

        # Workers pull one job envelope per iteration. A job carries its input index so the results land back in
        # input order; a job whose index is negative is the worker's STOP marker (one per worker, so every worker
        # terminates even when mappers fail). A cancelled pool skips further work instead of mapping it but keeps
        # draining to its STOP, so no worker is ever left parked on an empty channel by a sibling's failure.
        for ( 1 .. $concurrency ) {
            fiber {
                while (1) {
                    my $job = $jobs->get;
                    my ( $i, $val ) = @$job;
                    last if $i < 0;
                    next if $tok->cancelled;
                    my $rv;
                    my $map_err;
                    try { $rv = $code->($val) } catch ($e) {
                        $map_err = $e
                    }
                    if ($map_err) {
                        $first_error //= $map_err;    # the first mapper error wins
                        $tok->cancel;                 # fail fast: siblings stop at their next item boundary
                        last;
                    }
                    $results[$i] = $rv;
                }
                $wg->done;
            };
        }

        # The feeder delivers every envelope (the items, then the STOP markers) without ever parking on the
        # channel: a full channel is drained by the workers, so try_put + yield makes progress and finishes.
        fiber {
            my $idx       = 0;
            my @envelopes = map { [ $idx++, $_ ] } @items;
            push @envelopes, ( [-1] ) x $concurrency;
            for my $env (@envelopes) {
                while ( !$jobs->try_put($env) ) {
                    yield;
                }
            }
            $wg->done;
        };
        my $ok = 1;
        my $err;
        try { $wg->wait } catch ($e) {
            $ok  = 0;
            $err = $e
        }
        unless ($ok) {

            # The caller was interrupted while parked (an enclosing nursery/with_timeout): cancel the pool and
            # drain it so no worker outlives the caller, then rethrow the caller's own error.
            $tok->cancel;

            # A separate variable on purpose: $err is the caller's own error and is rethrown below.
            try { $wg->wait } catch ($drain_err) {
            }
            die $err;
        }
        die $first_error if defined $first_error;
        return wantarray ? @results : \@results;
    }

    sub spawn {
        my $class = $_[0];
        my $code;
        if ( ref $class eq 'CODE' ) {
            $code  = $class;
            $class = __PACKAGE__;
        }
        else {
            $code = $_[1];
        }
        @_ = ();

        # Trace propagation: Local slots created with inherit => 1 have their current value copied
        # from the spawning fiber (the one resolving the spawn args - our caller, even after a nursery or actor
        # birth park) into the child before the child's body first reads it. The seed is captured here, before
        # spawn_fiber eagerly runs the body, and applied by a wrapper that runs in the child's own context, so
        # the child's stash is seeded before any get in the body. The parent's stash is untouched: the child
        # owns a shallow copy of each seeded value, so later set()s never cross either direction, exactly
        # today's per-fiber isolation, only seeded. With no inherit slots (or no values set) nothing is captured
        # and no wrapper is built, so the common spawn path is unchanged.
        my @seed;
        if (@INHERIT_LOCAL_IDS) {
            my $fid    = current_fid();
            my $parent = $fid >= 0 ? Acme::Parataxis->by_id($fid) : undef;
            if ($parent) {
                my $stash = _fiber_locals($parent);
                for my $id (@INHERIT_LOCAL_IDS) {
                    push @seed, [ $id, $stash->{$id} ] if exists $stash->{$id};
                }
            }
        }
        if (@seed) {
            my $orig = $code;
            $code = sub {
                my $child = Acme::Parataxis->by_id( current_fid() );
                if ($child) {
                    my $stash = _fiber_locals($child);
                    $stash->{ $_->[0] } = $_->[1] for @seed;
                }
                return $orig->(@_);
            };
        }
        my $fiber = Acme::Parataxis::spawn_fiber( $code, $class );
        if ( !ref $fiber ) {
            croak defined $fiber &&
                $fiber == -3 ?
                'could not allocate a fiber: this platform has no MAP_NORESERVE and the process has hit its address-space / data-segment budget (raise RLIMIT_DATA or lower set_max_fibers)'
                :
                'could not allocate a fiber: the fiber table is full (destroy some fibers first, or raise the limit with set_max_fibers)';
        }
        my $status = $fiber->[F_LAST_STATUS];
        if ( $status == 1 ) {
            my $err = $fiber->[F_ERROR];
            die $err if defined $err;
        }
        elsif ( $status == 0 ) {
            $fiber->[F_PRIORITY] //= 0;
            _enqueue($fiber);
        }
        return $fiber;
    }

    sub _submit_job ( $type, $arg, $timeout ) {
        my $rc = submit_c_job( $type, $arg, $timeout );
        if ( $rc < 0 ) {

            # The 1024-slot job queue is full. Yield once so the scheduler can drain completed jobs, then retry.
            Acme::Parataxis->yield;
            $rc = submit_c_job( $type, $arg, $timeout );
            croak "job queue full: could not submit the job after a scheduler tick (submit_c_job returned $rc)" if $rc < 0;
        }
        return 0;
    }

    # -- event-loop driver. When an event loop is attached (attach_loop), await_read / await_write /
    # -- await_sleep stop submitting blocking OS-thread-pool jobs per filehandle/sleep and instead register watches
    # -- and timers on the loop; run() hands control to the loop whenever every fiber is parked. The public contract
    # -- is unchanged (readiness with the pool path's result values; timeout resumes -1; an enclosing with_timeout /
    # -- nursery interrupt still throws), only the backing mechanism differs.
    sub attach_loop {
        my $o     = _arg_offset( $_[0] );
        my $thing = $_[$o];
        croak 'attach_loop() requires an event-loop object (Mojo::IOLoop, Mojo::Reactor or IO::Async::Loop)' unless defined $thing && ref $thing;
        @_ = ();
        croak 'attach_loop() cannot run while a run is already active' if $IS_RUNNING;
        require Acme::Parataxis::Driver;
        my $driver = Acme::Parataxis::Driver::wrap($thing);
        my $old    = $DRIVER;
        $DRIVER = $driver;
        return $old;
    }

    # Detach the event-loop driver, returning it and unwinding every watch/timer it still held (loops attached to a
    # shared scheduler are racy at best, so a driver session is always short: attach, run, detach).
    sub detach_loop {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        croak 'detach_loop() cannot run while a run is already active' if $IS_RUNNING;
        my $old = $DRIVER;
        $old->reset if $old;
        $DRIVER = undef;
        return $old;
    }

    # The currently attached driver (undef when the pool path is in effect). Mostly for diagnostics.
    sub loop {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        return $DRIVER;
    }

    # -- transparent unblocking (CORE::GLOBAL overrides). Opt-in only: never
    # -- installed by default. enable_transparent_unblocking() makes sleep/read/sysread
    # -- cooperative inside scheduled fibers (sleep -> await_sleep, read/sysread framed
    # -- on await_read) and delegates to the raw builtin outside one, so synchronous
    # -- CPAN modules become cooperative once they are compiled after installation.
    # -- Full coverage table and caveats live in Acme::Parataxis::Compat.
    sub enable_transparent_unblocking {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        require Acme::Parataxis::Compat;
        Acme::Parataxis::Compat->install;
        return 1;
    }

    sub disable_transparent_unblocking {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        require Acme::Parataxis::Compat;
        Acme::Parataxis::Compat->disable;
        return 1;
    }

    sub transparent_unblocking {
        my $o = _arg_offset( $_[0] );
        @_ = ();
        return 0 unless $INC{'Acme/Parataxis/Compat.pm'};
        return Acme::Parataxis::Compat->installed ? 1 : 0;
    }

    sub _driver_sleep ( $driver, $ms ) {
        my $fid = Acme::Parataxis->current_fid;
        croak 'await_sleep() must be called from inside a scheduled fiber' if $fid < 0;
        my $fired = 0;
        my $id    = $driver->timer( $ms, sub { $fired = 1; Acme::Parataxis::_scheduler_enqueue_by_id($fid) } );
        my $dereg = sub { $driver->cancel_timer($id) unless $fired };
        return _park( 'await_sleep', 1, $dereg );
    }

    # Register a read/write watch on the attached loop, arm the wait's own deadline timer, and park. Natural wake
    # returns 1; the wait's own deadline swallows its ::Timeout and returns -1 like the pool path does; an *enclosing*
    # with_timeout / nursery interrupt did not cancel our deadline token, so it propagates by dying.
    #
    my $WARNED_FD_SETSIZE = 0;

    sub _driver_wait ( $driver, $fh, $dir, $timeout, $reason ) {
        my $fid = Acme::Parataxis->current_fid;
        croak "$reason() must be called from inside a scheduled fiber" if $fid < 0;

        # A loop whose readiness comes from select() cannot name a descriptor at or past the platform's
        # FD_SETSIZE - 256 on NetBSD, 64 for winsock, 1024 on Linux - and the fd_set in that case belongs to
        # the loop library rather than to us, so there is nothing here to widen. Registering the watch anyway
        # would either never fire or corrupt the loop's own stack, so refuse it. The worker-pool path answers
        # the same way for the same reason (see worker_thread in Parataxis.c), and -1 is what a deadline
        # produces too, so a caller already knows how to read it. Worth saying out loud once, because the
        # limit is the platform's and a workload sized on another OS can sail past it unnoticed.
        #
        # fileno croaks on something that is not a handle at all, and whatever the driver says about that is a
        # better message than anything invented here, so an answer of undef means "no descriptor to check" and
        # the handle goes on to the driver as it always did. An in-memory file answers -1, which is under any
        # ceiling, and needs no watch anyway.
        my $fd;
        try { $fd = fileno $fh } catch ($e) {
        }    # not a handle at all: no descriptor to check
        if ( defined $fd && $fd >= Acme::Parataxis::fd_setsize() ) {
            warn "Acme::Parataxis: $reason() refused: descriptor $fd is at or past this platform's FD_SETSIZE (" .
                Acme::Parataxis::fd_setsize() .
                "), which a select()-based readiness stack cannot name. Further refusals will not be reported.\n"
                unless $WARNED_FD_SETSIZE++;
            return -1;
        }
        my $wake = sub { Acme::Parataxis::_scheduler_enqueue_by_id($fid) };
        if ( $dir eq 'read' ) { $driver->watch_read( $fh, $wake ) }
        else                  { $driver->watch_write( $fh, $wake ) }
        my $deadline;
        my $timer_id;
        $timeout //= 5000;    # match the worker-pool default, which also maps 0/negative to 5000
        $timeout = 5000 if $timeout <= 0;

        if ( $timeout > 0 ) {
            my $have_ct = do { require Acme::Parataxis::CancellationToken; 1 };
            $deadline = Acme::Parataxis::CancellationToken->new( kind => 'timeout' ) if $have_ct;
            $deadline->register;
            $timer_id = $driver->timer( $timeout, sub { $deadline->cancel } );
        }
        my $out = 1;
        my $dying;
        my $dereg = sub {
            $driver->unwatch($fh);
            $driver->cancel_timer($timer_id) if defined $timer_id;
            $deadline->unregister            if defined $deadline;
        };
        my $ok = 1;
        my $err;
        try { Acme::Parataxis::_park( $reason, 1, $dereg ) }
        catch ($e) { $ok = 0; $err = $e }
        finally { $dereg->() }    # idempotent: on an interrupt _park already ran it, on a natural wake this is the cleanup
        if ( !$ok ) {
            if ( defined $deadline && $deadline->cancelled && ref($err) && $err->isa('Acme::Parataxis::Error::Timeout') ) {
                $out = -1;        # this wait's own deadline expired; the pool path resumes (not throws) on timeout
            }
            else { $dying = $err }
        }
        $deadline->unregister if defined $deadline;
        $deadline->cancel     if defined $deadline;
        die $dying            if defined $dying;
        return $out;
    }

    # Acme::Parataxis->advance($ms): inside a virtual run, jump the virtual clock forward $ms and wake everything that
    # fires as of the new time. A nudge, not a wait: the calling fiber keeps running (woken fibers run on the next
    # scheduler pass), so the "advance, then yield/return, then observe" test choreography in the docs is the idiom.
    # Returns the new virtual time in ms. Croaks outside a virtual run - the wall clock cannot be wound forward.
    sub advance {
        my $o  = _arg_offset( $_[0] );
        my $ms = $_[$o] // 0;
        @_ = ();
        croak 'advance() only makes sense inside run( virtual => 1, ... )' unless defined $VIRTUAL_CLOCK;
        croak 'advance() requires a non-negative number of milliseconds' if $ms < 0;
        $VIRTUAL_CLOCK += $ms;
        _fire_virtual($VIRTUAL_CLOCK);
        return $VIRTUAL_CLOCK;
    }

    sub await_sleep {
        my $o = _arg_offset( $_[0] );
        $o++ if $o == 0 && !defined $_[0];
        my $ms = $_[$o] // 0;
        @_ = ();
        if ( defined $VIRTUAL_CLOCK && $ms > 0 ) {
            my $fid = Acme::Parataxis->current_fid;
            croak 'await_sleep() must be called from inside a scheduled fiber' if $fid < 0;
            _arm_virtual_timer( $fid, $ms );
            return _park('await_sleep');
        }
        if ( $DRIVER && $ms > 0 ) {
            return _driver_sleep( $DRIVER, $ms );
        }
        _submit_job( 0, $ms, 0 );
        return _park('await_sleep');
    }

    sub await_core_id {
        @_ = ();
        _submit_job( 1, 0, 0 );
        return _park('await_core_id');
    }

    sub await_read {
        my $o = _arg_offset( $_[0] );
        $o++ if $o == 0 && !defined $_[0];
        my $fh      = $_[$o];
        my $timeout = $_[ $o + 1 ] // 5000;
        @_ = ();
        my $fileno = fileno($fh);
        die 'Not a valid filehandle' unless defined $fileno;
        if ($DRIVER) {
            return _driver_wait( $DRIVER, $fh, 'read', $timeout, 'await_read' );
        }
        my $handle = $^O eq 'MSWin32' ? win32_get_osfhandle($fileno) : $fileno;
        _submit_job( 2, $handle, $timeout );
        return _park('await_read');
    }

    sub await_write {
        my $o = _arg_offset( $_[0] );
        $o++ if $o == 0 && !defined $_[0];
        my $fh      = $_[$o];
        my $timeout = $_[ $o + 1 ] // 5000;
        @_ = ();
        my $fileno = fileno($fh);
        die 'Not a valid filehandle' unless defined $fileno;
        if ($DRIVER) {
            return _driver_wait( $DRIVER, $fh, 'write', $timeout, 'await_write' );
        }
        my $handle = $^O eq 'MSWin32' ? win32_get_osfhandle($fileno) : $fileno;
        _submit_job( 3, $handle, $timeout );
        return _park('await_write');
    }

    sub maybe_yield {
        @_ = ();
        my $result = Acme::Parataxis::_maybe_yield();
        return unless defined $result;
        return wantarray ? @$result : $result->[-1];
    }

    sub set_preempt_threshold {
        my $o = _arg_offset( $_[0] );
        croak 'set_preempt_threshold() expects a threshold value' unless @_ > $o;
        Acme::Parataxis::_set_preempt_threshold( $_[$o] // 0 );
    }
    sub tid            { get_os_thread_id_export() }
    sub current_fid    { get_current_parataxis_id() }
    sub root           { state $root //= Acme::Parataxis::Root->new() }
    sub max_threads () { Acme::Parataxis::get_max_thread_pool_size() }
    sub max_fibers ()  { Acme::Parataxis::get_max_fibers() }

    # The highest descriptor number an fd_set can name on this platform: 1024 on Linux, macOS and FreeBSD,
    # 256 on NetBSD, 64 for winsock. It is a property of the C library rather than a constant, and it bounds
    # the descriptor NUMBER, not the number of handles - so size a workload of N watched sockets against it
    # and not against N. Read it from C because nothing in perl can: `getconf FD_SETSIZE` is not a valid
    # symbol and answers 20, and Fcntl::FD_SETSIZE() dies at runtime.
    sub fd_setsize () { Acme::Parataxis::get_fd_setsize() }

    # Scheduler internals
    sub _scheduler_enqueue_by_id ($fid) {
        return if $SCHEDULER_QUEUED{$fid};
        if ( my $fiber = Acme::Parataxis->by_id($fid) ) {
            _enqueue($fiber);
        }
    }

    sub poll_io {
        my @ready;
        while (1) {
            my $job_idx = check_for_completion();
            last if $job_idx == -1;
            my $fid = get_job_coro_id($job_idx);
            my $res = get_job_result($job_idx);
            push @ready, [ $fid, $res ];
            free_job_slot($job_idx);
        }
        return @ready;
    }

    sub _handle_run ( $fiber, $status ) {
        if ( $status == 1 ) {
            Acme::Parataxis::_mark_done($fiber);
            my $err = $fiber->[F_ERROR];

            # A scheduled fiber that dies unwinds the whole run *unless* it has an observer (an awaiting parent, an
            # on_ready callback). With an observer the error is deliberately left for the observer to rethrow at the
            # await/call site, which lets a cancelled wait surface to its own awaiter without killing the block.
            die $err if defined $err && !@{ $fiber->[F_CALLBACKS] || [] };
            $fiber->[F_CALLBACKS] = [];    # one-shot, already fired by set_result/set_error; dropping the refs lets
            return 1;                      # a callback that captured the fiber (e.g. a nursery observer) cycle out
        }
        if ( $status == 0 ) {
            $fiber->[F_PRIORITY] //= 0;
            _enqueue($fiber);
        }
        return $status;
    }

    sub run (@raw) {
        my $o = _arg_offset( $raw[0] );
        my @a = @raw[ $o .. $#raw ];
        my ( $code, $virtual, $on_shutdown );
        if ( @a == 1 && ref $a[0] eq 'CODE' ) {
            $code = $a[0];
        }
        elsif ( @a >= 2 && @a % 2 == 0 ) {
            my %opt = @a;
            my @bad = grep { $_ ne 'code' && $_ ne 'virtual' && $_ ne 'on_shutdown' } keys %opt;
            croak 'run() unknown option(s): ' . join( ', ', @bad ) if @bad;
            croak 'run() needs the code option' unless ref $opt{code} eq 'CODE';
            $code        = $opt{code};
            $virtual     = $opt{virtual} ? 1 : 0;
            $on_shutdown = $opt{on_shutdown};
            if ( defined $on_shutdown && ref $on_shutdown ) {
                require Acme::Parataxis::CancellationToken;
                my $is_tok = 0;
                if ( ref $on_shutdown ne 'CODE' ) {
                    try { $is_tok = $on_shutdown->isa('Acme::Parataxis::CancellationToken') || 0 } catch ($e) {
                        $is_tok = 0
                    }
                }
                croak 'run() on_shutdown must be a true value, a code ref, or a CancellationToken' unless ref $on_shutdown eq 'CODE' || $is_tok;
            }
        }
        croak 'run() needs a CODE ref: run( $code ), or run( code => $code, ... )' unless ref $code eq 'CODE';
        if ($IS_RUNNING) {

            # Nested run/async inside a shared global scheduler. Queue a fresh fiber for the block and park the current
            # fiber until it completes. The on_shutdown option is only for the outermost run: an inner run must not
            # touch %SIG (the global handler table belongs to the top-level process lifecycle).
            my $fiber = __PACKAGE__->new( code => $code );
            _enqueue($fiber);
            return $fiber->await;
        }
        @SCHEDULER_QUEUE  = ();
        %SCHEDULER_QUEUED = ();
        $IS_RUNNING       = 1;

        # run( virtual => 1 ) turns on the virtual clock for the whole run. Everything the scheduler waits
        # on (and every mock_time read) then rides $VIRTUAL_CLOCK, and the idle path fast-forwards it instead of
        # sleeping, so timeouts can be exercised in microseconds. Saved/restored so a non-virtual run after a virtual
        # one (or vice versa) is exactly wall-clock behavior again.
        my $saved_clock = $VIRTUAL_CLOCK;
        if ($virtual) {
            $VIRTUAL_CLOCK     = 0;
            %VIRTUAL_DEADLINES = ();
            @VIRTUAL_TIMERS    = ();
        }

        # Snapshot the fibers that were already alive before this run. A fiber parked by a *previous* deadlocked run
        # can never be woken again, but the C table still counts it as live; the deadlock detector below must only
        # consider fibers that actually belong to this run, otherwise any run after a deadlock would be misread as
        # another deadlock. (Leaked fibers keep their C slot occupied, so their fids cannot be reused in between.)
        my %PRESET_FIBERS = map { $_ => 1 } _live_fiber_ids();
        my $main_fiber    = __PACKAGE__->new( code => $code );

        # on_shutdown => opts the OUTERMOST run into installing SIGINT/SIGTERM handlers for the run's lifetime
        # (the previous handlers are restored when it ends). The first signal - or, when the option is a pre-made
        # CancellationToken, its cancel() from anywhere - fires the shutdown token and interrupts every fiber this run
        # created (the run's root fiber included), so they unwind, run their own cleanup (defers/DESTROYs), and the
        # loop drains them; run() then returns the conventional interrupted status (130 for INT, 143 for TERM) instead
        # of rethrowing their Error::Cancelled. A second signal restores the previous handlers and re-raises the signal
        # so the default disposition kills the process - the handler never blocks a second Ctrl+C. A code ref passed as
        # the option receives the token (already fired) so a process can flush logs or stop servers before run() reports
        # the status; passing a CancellationToken means the caller owns the token and can begin the shutdown
        # programmatically (a health port, a parent process, a test) as well as from a signal.
        my ( $shutdown_token, $shutdown_status, $shutdown_fired, $shutdown_cb );
        my ( $old_int,        $old_term );
        my ( $fire,           $sig_pending );
        my $interrupt_run_fibers = sub {
            for my $fid ( _live_fiber_ids() ) {
                next if $PRESET_FIBERS{$fid};
                my $fiber = __PACKAGE__->by_id($fid);
                _interrupt( $fid, 'cancel' ) if $fiber && !$fiber->is_done;
            }
        };
        if ($on_shutdown) {
            require Acme::Parataxis::CancellationToken;
            my $is_shutdown_token = 0;
            if ( ref $on_shutdown ne 'CODE' ) {
                try { $is_shutdown_token = $on_shutdown->isa('Acme::Parataxis::CancellationToken') || 0 } catch ($e) {
                    $is_shutdown_token = 0
                }
            }
            $shutdown_token  = $is_shutdown_token         ? $on_shutdown : Acme::Parataxis::CancellationToken->new;
            $shutdown_cb     = ref $on_shutdown eq 'CODE' ? $on_shutdown : undef;
            $shutdown_status = 130;
            $old_int         = $SIG{INT};
            $old_term        = $SIG{TERM};
            $fire            = sub ($sig) {
                if ($shutdown_fired) {    # second signal: stop catching it; the restored default kills the process
                    $SIG{INT}  = $old_int;
                    $SIG{TERM} = $old_term;
                    kill $sig => $$;
                    return;
                }
                $shutdown_fired  = 1;
                $shutdown_status = $sig eq 'TERM' ? 143 : 130;
                $shutdown_token->cancel;
                $interrupt_run_fibers->();
            };

            # The async handlers only record a pending signal. $fire - the token cancel, the run-fiber interrupt sweep,
            # the scheduler queueing - runs at run()'s own checkpoint atop the scheduler loop instead: from inside the
            # handler it would execute at an arbitrary point mid-iteration, possibly while the loop is draining jobs /
            # resuming @ready fibers / mutating @SCHEDULER_QUEUE, where its effects on those fibers can be lost and the
            # run stalls until an outstanding C job finishes on its own schedule (a sleeping fiber rides out its full
            # deadline, so a Ctrl-C or kill can fire tens of seconds late). The checkpoint is the same place the
            # programmatic token-cancel sweep runs, which is what keeps the two paths deterministic under load.
            $SIG{INT}  = sub { $sig_pending ||= 'INT' };
            $SIG{TERM} = sub { $sig_pending ||= 'TERM' };
        }
        _enqueue($main_fiber);
        my $run_ok = 1;
        my $run_failure;
        try {
            while ($IS_RUNNING) {

                # Process a deferred signal at (and only at) this checkpoint - the one place in the loop
                # where no drain/@ready/@SCHEDULER_QUEUE manipulation is in flight, so the shutdown sweep below
                # cannot race the fibers it interrupts. See the comment at the $SIG{...} installs above.
                if ($sig_pending) {
                    ( my $sig, $sig_pending ) = ( $sig_pending, undef );
                    $fire->($sig);
                }

                # A shutdown token cancelled from inside the run (not just by a signal handler) begins the
                # graceful drain too. The token's own cancel() already interrupted whatever was registered against it;
                # this pass interrupts the rest of the run's fibers so every fiber winds down together.
                if ( $on_shutdown && !$shutdown_fired && $shutdown_token->cancelled ) {
                    $shutdown_fired = 1;
                    $interrupt_run_fibers->();
                }
                my @ready;
                if ( get_outstanding_jobs() ) {
                    my $out = [];
                    drain_jobs($out);
                    @ready = @$out;
                }
                for my $ready (@ready) {
                    my ( $fid, $res ) = @$ready;
                    my $fiber = __PACKAGE__->by_id($fid);
                    next unless $fiber;
                    _resume_hooks($fiber);
                    my $yield_val = $fiber->call($res);
                    if ( defined $fiber && !$fiber->is_done ) {
                        _enqueue($fiber) unless defined $yield_val && $yield_val eq 'WAITING';
                    }
                }
                if (@SCHEDULER_QUEUE) {
                    my @work = @SCHEDULER_QUEUE;
                    @SCHEDULER_QUEUE  = ();
                    %SCHEDULER_QUEUED = ();
                    for my $current (@work) {
                        next unless $current;
                        _resume_hooks($current);
                        _handle_run( $current, run_fiber_checked( $current->fid, undef ) );
                    }
                }
                my $active_count = get_live_fiber_count();
                if ( $IS_RUNNING && !@SCHEDULER_QUEUE && !@ready ) {
                    if ( get_outstanding_jobs() ) {
                        $DRIVER->poll_ready() if $DRIVER;    # fire any already-live driver events, best effort
                        usleep(1000);                        # Wait for background jobs to finish
                    }
                    elsif ( $DRIVER && $DRIVER->pending ) {

                        # Every fiber is parked and the attached event loop still has live watches/timers: hand the
                        # processor to the loop. Its readiness callbacks only ever enqueue fibers (_scheduler_enqueue_by_id),
                        # never run them, so no re-entrancy into the scheduler is possible; the outer loop runs them back
                        # on the next iteration.
                        $DRIVER->drive();
                    }
                    else {
                        # Virtual clock: the scheduler has no runnable work and no real jobs (real I/O never
                        # reaches here), but fibers are parked on virtual timers. Instead of sleeping on the wall clock
                        # (or declaring a deadlock), wind the virtual clock up to the earliest outstanding deadline and
                        # fire anything due, then re-loop to run the woken fibers. The clock never moves while any fiber
                        # is runnable or any real job is in flight, so only real waiting is accelerated.
                        if ( defined $VIRTUAL_CLOCK && @VIRTUAL_TIMERS ) {
                            my $earliest = $VIRTUAL_TIMERS[0][0];
                            $VIRTUAL_CLOCK = $earliest if $VIRTUAL_CLOCK < $earliest;
                            if ( _fire_virtual($VIRTUAL_CLOCK) ) {next}
                        }
                        if ( $active_count > scalar( keys %PRESET_FIBERS ) ) {

                            # A live fiber is stuck with nothing to do and no one to wake it and no timer to fire: this
                            # run is deadlocked.  Leave the scheduler in a clean, reusable state: stop this run, clear the
                            # queues, and do NOT treat it as a nested inner run (that path requires an enclosing scheduled
                            # fiber). Preset (leaked) fibers from a previously deadlocked run are excluded from the count
                            # above so they cannot make a later healthy run look deadlocked; they stay parked forever in
                            # the C table but are harmless because the count below only ever triggers on fibers created
                            # by this run.
                            $IS_RUNNING       = 0;
                            @SCHEDULER_QUEUE  = ();
                            %SCHEDULER_QUEUED = ();
                            my $rows = _fiber_snapshot();
                            my @mine = grep { !$PRESET_FIBERS{ $_->{fid} } } @$rows;
                            my $body = '';
                            for my $r (@mine) {
                                $body .= sprintf(
                                    "  fiber #%-3d %-8s %-17s %s\n",
                                    $r->{fid}, $r->{state},
                                    $r->{reason} ? $r->{reason}[0]                               : '-',
                                    $r->{reason} ? sprintf( '%s:%d', @{ $r->{reason} }[ 1, 2 ] ) : '-'
                                );
                                for my $bt ( @{ $r->{reason}[3] // [] } ) {
                                    $body .= sprintf( "        at %s:%d  %s\n", @$bt[ 1, 2, 3 ] );
                                }
                            }
                            $body .= "  (no live fibers from this run)\n" unless @mine;
                            my $leaked = @$rows - @mine;
                            $body .= "  ($leaked previously leaked fiber(s) from an older deadlocked run, omitted)\n" if $leaked;

                            # Tear the deadlocked run's own parked fibers out of the depth registry -- destroy_coro-equivalent
                            # purging at the moment this run's torn-down stack is detected. They are parked and nothing will
                            # ever resume them (this run is ending and the records stay leaked so their fids cannot be reused),
                            # so their parked claims must leave now: left in place they pin CvDEPTH above depths no live frame
                            # occupies, and every later park of the same CV enters one level high ("poisoned depth"). With the
                            # claims gone and the frames unwound (si_cxix = -1), the next swap's Pass 1c releases any pinned level.
                            para_cvreg_purge_fiber($_) for map { $_->{fid} } @mine;
                            die 'FATAL: deadlock detected: no runnable work and no outstanding jobs, but ' .
                                $active_count .
                                " live fiber(s). Parked in this run:\n" .
                                $body;
                        }
                        $IS_RUNNING = 0 if defined $main_fiber && $main_fiber->is_done;
                    }
                }
            }

            # No success marker is needed here, and deliberately so. This used to be an eval whose return
            # value was read as the success flag, so a *clean* exit whose last expression happened to be
            # false produced a defined-but-empty $@ that was then rethrown -- every normal run ended in
            # die '' ("Died at ..."). The catch below is the only thing that can set $run_failure.
        }
        catch ($e) { $run_ok = 0; $run_failure = $e }

        # An abort (an unobserved fiber death unwound the whole loop) ends the run with its remaining
        # fibers parked, abandoned exactly like a deadlocked run's. Nothing resumes them now, so purge
        # their parked claims the same way the deadlock branch does, before the next run can re-park in
        # a shared CV ("poisoned depth"). The fiber records stay leaked, so only this run's OWN fibers
        # are touched -- fibers from an older deadlocked run were already purged when their run died.
        # A clean stop must NOT purge: its parked leftovers are still resumable (their own jobs/waits will
        # fire), and the next run drains them -- tearing them down here would leak unusable records that
        # pin get_live_fiber_count() forever, which the cross-run stress tests assert against.
        if ( !$run_ok ) {
            para_cvreg_purge_fiber($_) for grep { !$PRESET_FIBERS{$_} } _live_fiber_ids();
        }
        $IS_RUNNING = 0;              # always leave the scheduler reusable, even when a fiber blew up
        $DRIVER->reset if $DRIVER;    # unwind every watch/timer this run left on the attached loop
        if ($on_shutdown) {           # the handler table is global: restore it no matter how the run ended
            $SIG{INT}  = $old_int;
            $SIG{TERM} = $old_term;
        }
        %VIRTUAL_DEADLINES = ();
        @VIRTUAL_TIMERS    = ();              # a virtual run's timers die with the run
        $VIRTUAL_CLOCK     = $saved_clock;    # whatever the next run does, the wall clock is the default
        if ( $on_shutdown && $shutdown_fired ) {
            $shutdown_cb->($shutdown_token) if $shutdown_cb;

            # The shutdown interrupt makes the run's fibers die with Error::Cancelled, which is the expected, drained
            # outcome of a signal, not a failure: run() reports the conventional interrupted status instead of
            # rethrowing it. Any other error still propagates.
            if ( defined $run_failure && ref $run_failure && $run_failure->isa('Acme::Parataxis::Error::Cancelled') ) {
                $run_failure = undef;
            }
            die $run_failure if defined $run_failure;
            return $shutdown_status;
        }
        die $run_failure if defined $run_failure;    # rethrow a fiber's uncaught error only after cleaning up
        return $main_fiber->[F_RESULT];
    }
    sub stop () { $IS_RUNNING = 0 }

    sub new ( $class, %args ) {
        my $self = bless [ $args{code}, 0, undef, undef, undef, 0, [], undef, undef, 0, undef, undef, undef, [] ], $class;
        my $fid  = Acme::Parataxis::create_fiber( $args{code}, $self );
        croak $fid == -3 ?
            'could not allocate a fiber: this platform has no MAP_NORESERVE and the process has hit its address-space / data-segment budget (raise RLIMIT_DATA or lower set_max_fibers)'
            :
            'could not allocate a fiber: the fiber table is full (destroy some fibers first, or raise the limit with set_max_fibers)'
            if $fid < 0;
        $self->[F_FID] = $fid;
        return $self;
    }
    sub fid   ($self) { $self->[F_FID] }
    sub code  ($self) { $self->[F_CODE] }
    sub error ($self) { $self->[F_ERROR] }

    # Higher numbers run first; ties are broken in the FIFO order they were enqueued in. The default is 0.
    sub priority {
        my $self = shift;
        my $prio = $self->[F_PRIORITY] // 0;
        return $prio unless @_;
        my $n = shift;
        $self->[F_PRIORITY] = $n;
        my $fid = $self->[F_FID];
        if ( delete $SCHEDULER_QUEUED{$fid} ) {
            @SCHEDULER_QUEUE = grep { $_->[F_FID] != $fid } @SCHEDULER_QUEUE;
            _enqueue($self);
        }
        return $n;
    }
    sub is_ready ($self) { $self->[F_IS_READY] }

    sub set_result {
        my ( $self, $val ) = @_;
        return if $self->[F_IS_READY];
        $self->[F_RESULT]   = $val;
        $self->[F_IS_READY] = 1;
        $_->($self) for @{ $self->[F_CALLBACKS] };
    }

    sub set_error ( $self, $err ) {
        return if $self->[F_IS_READY];
        $self->[F_ERROR]    = $err;
        $self->[F_IS_READY] = 1;
        $_->($self) for @{ $self->[F_CALLBACKS] };
    }

    sub _result ($self) {
        croak 'Future not ready' unless $self->[F_IS_READY];
        return $self->[F_RESULT];
    }
    sub result ($self) { return _result($self) }

    sub _clear_result ($self) {
        $self->[F_RESULT] = undef;
        $self->[F_ERROR]  = undef;
    }

    sub _mark_done ($self) {
        return if $self->[F_IS_DONE];
        $self->[F_IS_DONE] = 1;
        if ( defined $self->[F_FID] && $self->[F_FID] >= 0 ) {
            delete $PARKED{ $self->[F_FID] };
            delete $PARK_REGS{ $self->[F_FID] };
            _recall_virtual_timer( $self->[F_FID] );    # a finished fiber must not leave a virtual timer behind
            delete $FIBER_LOCALS{ refaddr($self) };
            $self->[F_FID] = -1;
        }
    }

    sub call ( $self, @args ) {
        croak 'Cannot call a finished fiber' if $self->[F_IS_DONE];
        my $rv = Acme::Parataxis::coro_call( $self->[F_FID], \@args );
        return unless defined $self;
        if ( $self->is_done ) {
            my $err = $self->[F_ERROR];

            # Observer-gated rethrow, like _handle_run: a fiber that died while watched (an awaiting parent or an
            # on_ready callback) keeps its error for the observer to rethrow at its await/call site instead of
            # killing the run loop. This is the wake-by-job-completion path (@ready), whose deaths are the one
            # observer-gated hole left open: a child that dies right after its own sleep job must not kill run().
            die $err if defined $err && !@{ $self->[F_CALLBACKS] || [] };
        }
        return unless defined $rv;
        return ( ref $rv eq 'ARRAY' ) ? ( wantarray ? @$rv : $rv->[-1] ) : $rv;
    }

    sub transfer ( $self, @args ) {
        croak 'Cannot transfer to a finished fiber' if $self->is_done;
        my $rv = Acme::Parataxis::coro_transfer( $self->[F_FID], \@args );
        if ( $self->is_done ) {
            my $err = $self->[F_ERROR];
            die $err if defined $err;
        }
        return unless defined $rv;
        return ( ref $rv eq 'ARRAY' ) ? ( wantarray ? @$rv : $rv->[-1] ) : $rv;
    }

    sub is_done ($self) {
        if ( $self->[F_IS_DONE] ) {
            delete $FIBER_LOCALS{ refaddr($self) };
            return 1;
        }
        if ( defined $self->[F_FID] && $self->[F_FID] >= 0 && Acme::Parataxis::is_finished( $self->[F_FID] ) ) {
            $self->[F_IS_DONE] = 1;
            my $old_fid = $self->[F_FID];
            delete $PARKED{$old_fid};
            delete $PARK_REGS{$old_fid};
            delete $FIBER_LOCALS{ refaddr($self) };
            $self->[F_FID] = -1;
            Acme::Parataxis::destroy_coro($old_fid);
            return 1;
        }
        return 0;
    }
    sub wait_reason ($self) { $self->[F_WAIT_REASON] }    # [reason, file, line, backtrace] while parked, undef otherwise

    sub wait ($self) {
        if ( !$self->is_done && Acme::Parataxis->current_fid < 0 ) {
            croak 'wait() must be called from inside the scheduler, or the fiber must already be done';
        }
        my $fid    = Acme::Parataxis->current_fid;
        my $waiter = $fid >= 0 ? Acme::Parataxis->by_id($fid) : undef;    # the fiber doing the busy-wait
        $waiter->[F_WAIT_REASON] = [ 'fiber wait', (caller)[ 1, 2 ] ] if $waiter;
        Acme::Parataxis->yield('WAITING_FOR_CHILD') until $self->is_done;
        $waiter->[F_WAIT_REASON] = undef if $waiter;
        return _result($self);
    }

    sub on_ready ( $self, $cb ) {
        if   ( $self->[F_IS_READY] ) { $cb->($self) }
        else                         { push @{ $self->[F_CALLBACKS] }, $cb }
    }

    sub await ($target) {

        # await() is exported as a plain function; await($fut) must delegate to the await-capable receiver's own
        # method (e.g. Future), while fiber objects (which ARE Acme::Parataxis) keep the arrayref-slot path.
        # The signature keeps @_ unreified here: await() parks and is resumed on this same pad.
        if ( builtin::blessed($target) && $target->can('await') && !$target->isa(__PACKAGE__) ) {
            return $target->await;
        }
        my $self  = $target;
        my $ready = $self->[F_IS_READY];
        if ( !$ready ) {
            croak 'await() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
            my $fid = Acme::Parataxis->current_fid;
            $self->[F_WAITER] = $fid;
            $self->on_ready( \&_wake_waiter );
            _park( 'fiber await', 1, sub { $self->[F_WAITER] = undef if defined $self->[F_WAITER] && $self->[F_WAITER] == $fid } );
            $ready = $self->[F_IS_READY];
        }
        croak 'Future not ready' unless $ready;
        delete $FIBER_LOCALS{ refaddr($self) };    # the fiber is done now; its locals die with it (no-op for Futures)
        die $self->[F_ERROR] if defined $self->[F_ERROR];
        $self->[F_RESULT];
    }

    sub _wake_waiter ($self) {
        return unless defined $self->[F_WAITER];
        Acme::Parataxis::_scheduler_enqueue_by_id( $self->[F_WAITER] );
        $self->[F_WAITER] = undef;
    }

    sub DESTROY($self) {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        delete $FIBER_LOCALS{ refaddr($self) };
        if ( defined $self->[F_FID] && $self->[F_FID] >= 0 ) {
            delete $PARKED{ $self->[F_FID] };
            delete $PARK_REGS{ $self->[F_FID] };
            Acme::Parataxis::destroy_coro( $self->[F_FID] );
            $self->[F_FID] = -1;
        }
    }
    sub by_id ( $class, $fid ) { Acme::Parataxis::get_fiber_by_id($fid) }

    # Registered-actor lookup (the whereis table). Returns the handle of the actor spawned with that name, or undef
    # when nothing (or nobody alive) answers to it. Registration is removed when an actor stops, dies, or is
    # destroyed, so a dead actor never answers a lookup. Works as a plain function (Acme::Parataxis::actor('x')) or
    # a class method (Acme::Parataxis->actor('x')); whereis is an alias.
    sub actor {
        my $o    = _arg_offset( $_[0] );
        my $name = $_[$o];
        @_ = ();
        return undef unless defined $name;
        return $ACTOR_REGISTRY{$name};
    }

    sub whereis {
        my $o    = _arg_offset( $_[0] );
        my $name = $_[$o];
        @_ = ();
        return actor($name);
    }

    sub _dispatch_callbacks ($self) {
        $_->($self) for @{ $self->[F_CALLBACKS] };
    }
    class    #
        Acme::Parataxis::Root {
        field $fid : reader = -1;    # For now

        method transfer (@args) {
            my $rv = Acme::Parataxis::coro_transfer( -1, \@args );
            return unless defined $rv;
            return ( ref $rv eq 'ARRAY' ) ? ( wantarray ? @$rv : $rv->[-1] ) : $rv;
        }
    }
    END { cleanup() unless ${^GLOBAL_PHASE} eq 'DESTRUCT' }
}
1;
