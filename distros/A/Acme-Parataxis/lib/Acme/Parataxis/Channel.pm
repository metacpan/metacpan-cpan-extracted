use v5.40;
use feature 'class';
no warnings 'experimental::class', 'experimental::try', 'recursion';
#
class Acme::Parataxis::Channel v0.1.1 {
    use Acme::Parataxis qw[fiber await_sleep];
    use Acme::Parataxis::CancellationToken;
    use Acme::Parataxis::Semaphore;
    use Carp qw[croak];
    #
    field $capacity : reader : param //= 2_000_000_000;
    field $timeout  : reader : param //= 0;               # per-channel default wait bound in ms; 0 (and undef) means none
    field $sem_get = Acme::Parataxis::Semaphore->new( count => 0 );
    field $sem_put = Acme::Parataxis::Semaphore->new( count => $capacity );
    field @data : reader;
    field @select_waiters;                                # [fid, op] pairs parked here by select(); op is 'get' or 'put'
    ADJUST {
        $capacity >= 1                    or die "Channel capacity must be >= 1 (got $capacity)\n";
        defined $timeout && $timeout >= 0 or die "Channel timeout must be a non-negative number of milliseconds (got $timeout)\n";
    }

    # Runs $op (a get/put body that parks through the channel semaphores) under the channel's default
    # wait bound. The deadline is armed only when the op may actually park ($may_park): a ready channel
    # never pays for a timer. Exactly like Channel::select's deadline - one token registered before the
    # park (register-then-arm closes the lost-wakeup window) and one timer, re-used across the
    # semaphore's internal re-parks; Error::Timeout on expiry, the waiter unregistered from the
    # semaphore when interrupted. Teardown unregisters the caller and cancels the token on every exit,
    # which recalls the timer's armed sleep job instead of leaving a worker sleeping out the bound.
    method _with_deadline ( $may_park, $op ) {
        return $op->() if !defined $timeout || $timeout <= 0 || !$may_park;
        my $deadline = Acme::Parataxis::CancellationToken->new( kind => 'timeout' );
        $deadline->register;
        my $ms = $timeout;
        fiber {
            $deadline->register;
            try { await_sleep($ms); $deadline->cancel } catch ($e) {
            }    # swallows its own interrupt
        };
        my ( $ok, $err, @rv );
        $ok = 1;
        if (wantarray) {
            try { @rv = $op->() } catch ($e) {
                $ok  = 0;
                $err = $e
            }
        }
        else {
            try { $rv[0] = $op->() } catch ($e) {
                $ok  = 0;
                $err = $e
            }
        }
        $deadline->unregister;
        $deadline->cancel;
        die $err if !$ok;
        return wantarray ? @rv : $rv[0];
    }

    method put ($value) {
        return $self->_with_deadline(
            @data >= $capacity,
            sub {
                $sem_put->down( 'Channel put', 5 );
                push @data, $value;
                $sem_get->up;
                $self->_wake_select_waiters('get');
                1;
            }
        );
    }

    method put_priority ($value) {
        push @data, $value;
        $sem_get->up;
        $self->_wake_select_waiters('get');
        1;
    }

    method try_put ($value) {
        return 0 unless $sem_put->try;
        push @data, $value;
        $sem_get->up;
        $self->_wake_select_waiters('get');
        return 1;
    }

    method get () {
        return $self->_with_deadline(
            @data == 0,
            sub {
                $sem_get->down( 'Channel get', 5 );
                $sem_put->up;
                my $v = shift @data;
                $self->_wake_select_waiters('put');
                return $v;
            }
        );
    }

    method try_get () {
        return ( 0, undef ) unless $sem_get->try;
        $sem_put->up;
        my $v = shift @data;
        $self->_wake_select_waiters('put');
        return ( 1, $v );
    }
    method size () { scalar @data }

    method shutdown () {
        $sem_get->adjust(1_000_000_000);
        $self->_wake_select_waiters('get');
        1;
    }

    method adjust ($diff) {
        $sem_put->adjust($diff);
        $self->_wake_select_waiters('put');
        1;
    }
    method select_waiters () { scalar @select_waiters }    # introspection: how many fibers are parked in select() here

    method remove_waiter ($fid) {    # Unregisters the fiber from any internal wait queue; returns the number of entries removed.
        $sem_get->remove_waiter($fid) + $sem_put->remove_waiter($fid) + $self->_unregister_select_waiter($fid);
    }
    method _register_select_waiter ( $fid, $op ) { push @select_waiters, [ $fid, $op ]; return $fid; }

    method _unregister_select_waiter ($fid) {
        my $before = @select_waiters;
        @select_waiters = grep { $_->[0] != $fid } @select_waiters;
        return $before - @select_waiters;
    }

    method _wake_select_waiters ($op) {    # Wakes the select waiters waiting for $op, dropping stale fids
        return unless @select_waiters;
        my @still;
        for my $ent (@select_waiters) {
            my ( $fid, $want ) = @$ent;
            next if !defined Acme::Parataxis->by_id($fid);    # stale: dropped, not retained for the next wake
            if   ( $want eq $op ) { Acme::Parataxis::_scheduler_enqueue_by_id($fid) }
            else                  { push @still, $ent }
        }
        @select_waiters = @still;
        return;
    }

    # CSP select: wait on the first ready case and return its (channel, value). A plain package sub rather than a
    # method, since it has no channel of its own to dispatch on, so it takes the class as $class and is called as
    # Acme::Parataxis::Channel->select(...). Two probe/register phases -- probe without yielding first, fall back to
    # registering on every case in the channel's private @select_waiters, arming the shared deadline *after*
    # registration, then parking.
    sub select ( $class, @args ) {
        my ( $timeout, $default );
        my @cases;
        while (@args) {
            my $arg = shift @args;
            if ( ref $arg eq 'ARRAY' && @$arg >= 2 ) {
                my ( $ch, $op, @rest ) = @$arg;
                Carp::croak 'select() case channel must be an Acme::Parataxis::Channel' unless ref($ch) && $ch->isa('Acme::Parataxis::Channel');
                Carp::croak 'select() case op must be "get" or "put"'                   unless $op eq 'get' || $op eq 'put';
                Carp::croak 'select() "put" case requires a value' if $op eq 'put' && @$arg < 3;
                push @cases, [ $ch, $op, $rest[0] ];
            }
            elsif ( $arg eq 'timeout' ) {
                $timeout = shift @args;
                Carp::croak 'select() timeout must be a non-negative number of milliseconds' unless defined $timeout && $timeout >= 0;
            }
            elsif ( $arg eq 'default' ) {
                $default = shift @args;
                Carp::croak 'select() default must be a CODE ref' unless ref $default eq 'CODE';
            }
            else {
                Carp::croak 'select() arguments must be [ $channel, "get" | "put", $value? ] cases, with timeout/default options';
            }
        }
        Carp::croak 'select() needs at least one case' unless @cases;
        my $fid = Acme::Parataxis->current_fid;
        Carp::croak 'select() must be called from inside a scheduled fiber' if $fid < 0;

        # No explicit timeout: each case's channel-level default (Channel->new( timeout => $ms )) applies
        # and select parks until the earliest fires - so the shared deadline is the smallest positive
        # default among the cases. An explicit timeout option (including timeout => 0) always wins.
        if ( !defined $timeout ) {
            my @bounds = sort { $a <=> $b } grep { defined && $_ > 0 } map { $_->[0]->timeout } @cases;
            $timeout = @bounds ? $bounds[0] : undef;
        }

        # The timeout deadline is armed once on the first park and reused across re-parks, so a spurious wake can
        # never stack timers. "Register, then arm" (token.register before the sleep job) closes the lost-wakeup
        # window an await_sleep-only timeout would leave between the probe step and registration.
        my $deadline;
        my $timer_armed;
        my ( $out_ch, $out_val, $out_die ) = ( undef, undef, undef );
    OUTER: while (1) {

            # Phase 1 -- probe, no yield: shuffle so no ordering starves a case, commit the first match, and let
            # default run only when nothing is ready (it never parks).
            my @order = 0 .. $#cases;
            for ( my $i = $#order; $i > 0; $i-- ) {
                my $j = int rand( $i + 1 );
                @order[ $i, $j ] = @order[ $j, $i ];
            }
            for my $i (@order) {
                my ( $ch, $op, $v ) = @{ $cases[$i] };
                if ( $op eq 'get' ) {
                    my ( $ok, $got ) = $ch->try_get;
                    if ($ok) { ( $out_ch, $out_val ) = ( $ch, $got ); last OUTER; }
                }
                else {
                    if ( $ch->try_put($v) ) { ( $out_ch, $out_val ) = ( $ch, $v ); last OUTER; }
                }
            }
            if ( defined $default ) { ( $out_ch, $out_val ) = ( undef, $default->() ); last OUTER; }

            # Phase 2 -- register on every involved channel, arm the shared deadline, then park. On wake the
            # park's deregistrations were already dropped (_resume_hooks) or the per-channel wake skipped the
            # fiber, so re-probe exactly once and fall back to re-registering; the one-shot re-poll per wake is
            # natural here because registering happens before the next park.
            for my $case (@cases) { $case->[0]->_register_select_waiter( $fid, $case->[1] ); }
            if ( defined $timeout && $timeout > 0 ) {
                $deadline //= Acme::Parataxis::CancellationToken->new( kind => 'timeout' );
                $deadline->register;
                unless ($timer_armed) {
                    my $ms = $timeout;

                    # The timer registers on the shared deadline and swallows its own interrupt, so teardown can
                    # recall it when a case commits first instead of leaving a worker parked for the full $ms.
                    Acme::Parataxis::fiber {
                        $deadline->register;
                        try { Acme::Parataxis::await_sleep($ms); $deadline->cancel } catch ($e) {
                        }
                    };
                    $timer_armed = 1;
                }
            }
            my $dereg = sub {
                for my $case (@cases) { $case->[0]->_unregister_select_waiter($fid) }
                $deadline->unregister if defined $deadline;
            };
            my $ok = 1;
            my $err;
            try { Acme::Parataxis::_park( 'Channel select', 1, $dereg ) }
            catch ($e) { $ok = 0; $err = $e }
            finally { $dereg->() }    # idempotent: on interrupt _park already ran it; on a natural wake this is the cleanup
            if ( !$ok ) {

                # Our own deadline fired -> the API is (undef, undef) on timeout. A timeout sent by an *enclosing*
                # with_timeout/nursery did not cancel our token, so it propagates instead of being swallowed.
                if ( defined $deadline && $deadline->cancelled && ref($err) && $err->isa('Acme::Parataxis::Error::Timeout') ) {
                    ( $out_ch, $out_val ) = ( undef, undef );
                    last OUTER;
                }
                $out_die = $err;
                last OUTER;
            }
        }

        # Every exit funnels through here so the armed timeout helper is never orphaned: drop the select fiber off
        # the token first (a running fiber must not receive its own interrupt), then cancel to recall the timer's
        # sleep job. A deadline that already fired makes both steps no-ops.
        $deadline->unregister if defined $deadline;
        $deadline->cancel     if defined $deadline;
        die $out_die          if defined $out_die;
        return ( $out_ch, $out_val );
    }
};
#
1;
