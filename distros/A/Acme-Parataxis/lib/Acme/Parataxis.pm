use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use experimental qw[class try];

package Acme::Parataxis v0.1.0 {
    use Affix;
    use Config;
    use File::Spec;
    use File::Basename qw[dirname];
    use Time::HiRes    qw[usleep];
    use Exporter       qw[import];
    use Carp           qw[croak];
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                run spawn yield await stop async fiber
                await_sleep await_read await_write await_core_id
                current_fid tid root maybe_yield
                set_max_threads max_threads
                ]
        ]
    );
    #
    our @IPC_BUFFER;
    my $lib;
    my @SCHEDULER_QUEUE;
    my %SCHEDULER_QUEUED;
    my $IS_RUNNING = 0;

    # Fiber object layout: a flat arrayref of slots rather than perlclass objects (array access is much cheaper than
    # classes and even hash lookup on the hot spawn/await path).
    use constant {
        F_CODE        => 0,
        F_IS_DONE     => 1,
        F_ERROR       => 2,
        F_RESULT      => 3,
        F_FID         => 4,
        F_IS_READY    => 5,
        F_CALLBACKS   => 6,
        F_WAITER      => 7,
        F_LAST_STATUS => 8,
        F_PRIORITY    => 9
    };

    # Scheduler run queue.  Kept sorted by descending priority (stable for
    # equal priorities, so a group of same-priority fibers stays FIFO).
    sub _enqueue ($fiber) {
        my $fid = $fiber->[F_FID];
        return if $SCHEDULER_QUEUED{$fid};
        $SCHEDULER_QUEUED{$fid} = 1;
        my $prio = $fiber->[F_PRIORITY] // 0;
        my $i    = 0;
        $i++ while $i < @SCHEDULER_QUEUE && ( $SCHEDULER_QUEUE[$i]->[F_PRIORITY] // 0 ) >= $prio;
        splice @SCHEDULER_QUEUE, $i, 0, $fiber;
    }

    sub _bind_functions ($l) {
        affix $l, 'init_system',                       [],                             Int;
        affix $l, 'create_fiber',                      [ Pointer [SV], Pointer [SV] ], Int;
        affix $l, 'spawn_fiber',                       [ Pointer [SV], Pointer [SV] ], Pointer [SV];
        affix $l, 'coro_call',                         [ Int, Pointer [SV] ],          Pointer [SV];
        affix $l, 'run_fiber_checked',                 [ Int, Pointer [SV] ],          Int;
        affix $l, 'coro_transfer',                     [ Int, Pointer [SV] ],          Pointer [SV];
        affix $l, 'coro_yield',                        [ Pointer [SV] ],               Pointer [SV];
        affix $l, 'is_finished',                       [Int],                          Int;
        affix $l, 'get_fiber_by_id',                   [Int],                          Pointer [SV];
        affix $l, 'get_live_fiber_count',              [],                             Int;
        affix $l, 'destroy_coro',                      [Int],                          Void;
        affix $l, 'force_depth_zero',                  [ Pointer [SV] ],               Void;
        affix $l, 'cleanup',                           [],                             Void;
        affix $l, 'get_os_thread_id_export',           [],                             Int;
        affix $l, 'get_current_parataxis_id',          [],                             Int;
        affix $l, 'submit_c_job',                      [ Int, LongLong, Int ],         Int;
        affix $l, 'drain_jobs',                        [ Pointer [SV] ],               Void;
        affix $l, 'check_for_completion',              [],                             Int;
        affix $l, 'get_outstanding_jobs',              [],                             Int;
        affix $l, 'get_job_result',                    [Int],                          Pointer [SV];
        affix $l, 'get_job_coro_id',                   [Int],                          Int;
        affix $l, 'free_job_slot',                     [Int],                          Void;
        affix $l, 'get_thread_pool_size',              [],                             Int;
        affix $l, 'get_max_thread_pool_size',          [],                             Int;
        affix $l, 'set_max_threads',                   [Int],                          Void;
        affix $l, 'set_preempt_threshold',             [LongLong],                     Void;
        affix $l, [ 'maybe_yield' => '_maybe_yield' ], [],                             Pointer [SV];
        affix $l, 'get_preempt_count',                 [],                             LongLong;

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

    sub yield {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
            $invocant = __PACKAGE__;
        }
        my $result = coro_yield( \@_ );
        return unless defined $result;
        return ( ref $result eq 'ARRAY' ) ? ( wantarray ? @$result : $result->[-1] ) : $result;
    }

    sub spawn {
        my ( $class, $code ) = @_;
        if ( ref $class eq 'CODE' ) {
            $code  = $class;
            $class = __PACKAGE__;
        }
        my $fiber = Acme::Parataxis::spawn_fiber( $code, $class );
        croak 'could not allocate a fiber: the fiber table is full (destroy some fibers first)' unless $fiber && ref $fiber;
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

    sub await_sleep {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
        }
        my $ms = shift // 0;
        _submit_job( 0, $ms, 0 );
        return yield('WAITING');
    }

    sub await_core_id {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
        }
        _submit_job( 1, 0, 0 );
        return yield('WAITING');
    }

    sub await_read {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
        }
        my ( $fh, $timeout ) = @_;
        $timeout //= 5000;
        my $fileno = fileno($fh);
        die 'Not a valid filehandle' unless defined $fileno;
        my $handle = $^O eq 'MSWin32' ? win32_get_osfhandle($fileno) : $fileno;
        _submit_job( 2, $handle, $timeout );
        return yield('WAITING');
    }

    sub await_write {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
        }
        my ( $fh, $timeout ) = @_;
        $timeout //= 5000;
        my $fileno = fileno($fh);
        die 'Not a valid filehandle' unless defined $fileno;
        my $handle = $^O eq 'MSWin32' ? win32_get_osfhandle($fileno) : $fileno;
        _submit_job( 3, $handle, $timeout );
        return yield('WAITING');
    }

    sub maybe_yield {
        my $invocant = shift;
        if ( !defined $invocant ||
            ( ( ref $invocant || $invocant ) ne __PACKAGE__ && !( builtin::blessed($invocant) && $invocant->isa(__PACKAGE__) ) ) ) {
            unshift @_, $invocant if defined $invocant;
        }
        my $result = Acme::Parataxis::_maybe_yield();
        return unless defined $result;
        return wantarray ? @$result : $result->[-1];
    }
    sub tid            { get_os_thread_id_export() }
    sub current_fid    { get_current_parataxis_id() }
    sub root           { state $root //= Acme::Parataxis::Root->new() }
    sub max_threads () { Acme::Parataxis::get_max_thread_pool_size() }

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
            die $err if defined $err;
            return 1;
        }
        if ( $status == 0 ) {
            $fiber->[F_PRIORITY] //= 0;
            _enqueue($fiber);
        }
        return $status;
    }

    sub run ($code) {
        if ($IS_RUNNING) {

            # Nested run/async inside a shared global scheduler. Queue a fresh fiber for the block and park the current
            # fiber until it completes.
            my $fiber = __PACKAGE__->new( code => $code );
            _enqueue($fiber);
            return $fiber->await;
        }
        @SCHEDULER_QUEUE  = ();
        %SCHEDULER_QUEUED = ();
        $IS_RUNNING       = 1;
        my $main_fiber = __PACKAGE__->new( code => $code );
        _enqueue($main_fiber);
        while ($IS_RUNNING) {
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
                    _handle_run( $current, run_fiber_checked( $current->fid, undef ) );
                }
            }
            my $active_count = get_live_fiber_count();
            if ( $IS_RUNNING && !@SCHEDULER_QUEUE && !@ready ) {
                if ( get_outstanding_jobs() ) {
                    usleep(1000);    # Wait for background jobs to finish
                }
                else {
                    die 'FATAL: deadlock detected...' if $active_count > 0;
                    $IS_RUNNING = 0                   if defined $main_fiber && $main_fiber->is_done;
                }
            }
        }
        return $main_fiber->[F_RESULT];
    }
    sub stop () { $IS_RUNNING = 0 }

    sub new ( $class, %args ) {
        my $self = bless [ $args{code}, 0, undef, undef, undef, 0, [], undef, undef, 0 ], $class;
        my $fid  = Acme::Parataxis::create_fiber( $args{code}, $self );
        croak 'could not allocate a fiber: the fiber table is full (destroy some fibers first)' if $fid < 0;
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
            $self->[F_FID] = -1;
        }
    }

    sub call ( $self, @args ) {
        croak 'Cannot call a finished fiber' if $self->[F_IS_DONE];
        my $rv = Acme::Parataxis::coro_call( $self->[F_FID], \@args );
        return unless defined $self;
        if ( $self->is_done ) {
            my $err = $self->[F_ERROR];
            die $err if defined $err;
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
        return 1 if $self->[F_IS_DONE];
        if ( defined $self->[F_FID] && $self->[F_FID] >= 0 && Acme::Parataxis::is_finished( $self->[F_FID] ) ) {
            $self->[F_IS_DONE] = 1;
            my $old_fid = $self->[F_FID];
            $self->[F_FID] = -1;
            Acme::Parataxis::destroy_coro($old_fid);
            return 1;
        }
        return 0;
    }

    sub wait ($self) {
        if ( !$self->is_done && Acme::Parataxis->current_fid < 0 ) {
            croak 'wait() must be called from inside the scheduler, or the fiber must already be done';
        }
        Acme::Parataxis->yield('WAITING_FOR_CHILD') until $self->is_done;
        return _result($self);
    }

    sub on_ready ( $self, $cb ) {
        if   ( $self->[F_IS_READY] ) { $cb->($self) }
        else                         { push @{ $self->[F_CALLBACKS] }, $cb }
    }

    sub await ($self) {
        my $ready = $self->[F_IS_READY];
        if ( !$ready ) {
            croak 'await() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
            $self->[F_WAITER] = Acme::Parataxis->current_fid;
            $self->on_ready( \&_wake_waiter );
            Acme::Parataxis->yield('WAITING');
            $ready = $self->[F_IS_READY];
        }
        croak 'Future not ready' unless $ready;
        $self->[F_RESULT];
    }

    sub _wake_waiter ($self) {
        return unless defined $self->[F_WAITER];
        Acme::Parataxis::_scheduler_enqueue_by_id( $self->[F_WAITER] );
        $self->[F_WAITER] = undef;
    }

    sub DESTROY($self) {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        if ( defined $self->[F_FID] && $self->[F_FID] >= 0 ) {
            Acme::Parataxis::destroy_coro( $self->[F_FID] );
            $self->[F_FID] = -1;
        }
    }
    sub by_id ( $class, $fid ) { Acme::Parataxis::get_fiber_by_id($fid) }

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
