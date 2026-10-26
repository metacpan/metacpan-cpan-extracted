use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
#
# OTP-style supervisor trees: children are supervised actors (or nested supervisors) that are
# restarted whenever they die, according to a restart strategy, until a restart budget runs out -
# at which point the tree is torn down and run() fails with an aggregate
# Acme::Parataxis::Error::Supervisor. This is the "heal-fast" half of supervision's "supervision is
# deliberately out of scope" guardrail, and it is pure Perl on top of the existing park/wake
# machinery: one supervision fiber owns the tree and learns a child died through that child's own
# teardown (an actor's on_death hook, or a wrapper fiber around a nested supervisor's run).
class Acme::Parataxis::Supervisor v0.1.1 {
    use Acme::Parataxis qw[fiber];
    use Acme::Parataxis::Channel;
    use Acme::Parataxis::Error;
    use builtin     qw[blessed];
    use Time::HiRes qw[time];
    use Carp        qw[croak];

    # Restart strategy. OneForOne restarts only the child that died; OneForAll restarts every child
    # (they share state the death may have broken); RestForOne restarts the dead child and
    # everything started after it. max_restarts deaths within `within` seconds exhaust the budget:
    # the (max_restarts+1)-th death inside the window fails the supervisor instead of restarting.
    field $strategy     : reader : param = 'OneForOne';
    field $max_restarts : reader : param = 5;
    field $within       : reader : param = 60;

    # Supervised children in start order. Each is a spec ({name, factory, initial}) plus the live
    # bookkeeping for the instance currently running: `instance`, the `token` identifying that
    # attempt, `pending` (an event for it is still expected), `restarts`, and `index`.
    field @children;

    # The original supervise() arguments, so a restarted supervisor can rebuild its own subtree
    # from scratch instead of inheriting the dead one's instances.
    field @specs;

    # Restart budget: [ when, child name, reason ] for every restart still inside the window.
    field @budget;

    # Where dying instances report [ $child, $token, $err ]. Oversized so a report can never park a
    # fiber that is in the middle of tearing itself down.
    field $deaths;
    field $running  : reader = false;
    field $stopping : reader = false;
    field $started  : reader = false;
    ADJUST {
        croak "Supervisor->new: strategy must be OneForOne, OneForAll or RestForOne (got '$strategy')"
            unless defined $strategy && ( $strategy eq 'OneForOne' || $strategy eq 'OneForAll' || $strategy eq 'RestForOne' );
        croak 'Supervisor->new: max_restarts must be a non-negative integer'     unless defined $max_restarts && $max_restarts =~ /\A\d+\z/;
        croak 'Supervisor->new: within must be a non-negative number of seconds' unless defined $within       && $within =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
        $deaths = Acme::Parataxis::Channel->new( capacity => 4096 );
    }

    # Register a child. $thing is an Actor (adopted as-is for the first run, restarted with a fresh
    # mailbox), a Supervisor (the same, for a subtree), or a CODE ref factory returning either -
    # which is what you want when the child should not exist until the tree starts. The optional
    # name defaults to child_1, child_2, ... in registration order and must be unique.
    method supervise ( $thing, %opts ) {
        croak 'Supervisor->supervise() may not add children once run() has started' if $started;
        croak 'Supervisor->supervise() requires an Acme::Parataxis::Actor, an Acme::Parataxis::Supervisor, or a CODE ref factory'
            unless ref $thing eq 'CODE' ||
            ( blessed($thing) && ( $thing->isa('Acme::Parataxis::Actor') || $thing->isa('Acme::Parataxis::Supervisor') ) );
        my $unknown = join ', ', grep { $_ ne 'name' } sort keys %opts;
        croak "Supervisor->supervise(): unknown options: $unknown" if length $unknown;
        my $name = defined $opts{name} ? $opts{name} : 'child_' . ( scalar(@children) + 1 );
        croak 'Supervisor->supervise(): name must be a non-empty string'             if ref $name || !defined $name || $name eq '';
        croak "Supervisor->supervise(): a child named '$name' is already supervised" if grep { $_->{name} eq $name } @children;
        my ( $factory, $initial );

        if ( ref $thing eq 'CODE' ) {
            $factory = $thing;
        }
        elsif ( $thing->isa('Acme::Parataxis::Supervisor') ) {
            $factory = sub { $thing->_duplicate };
            $initial = $thing;
        }
        else {
            $factory = sub { $thing->respawn };
            $initial = $thing;
        }
        push @specs, [ $thing, %opts ];
        push @children,
            {
            name     => $name,
            factory  => $factory,
            initial  => $initial,
            instance => undef,
            token    => undef,
            pending  => 0,
            restarts => 0,
            index    => scalar @children
            };
        return $self;
    }

    # A fresh supervisor with the same configuration and the same children, every one of them
    # rebuilt from its factory: restarting a nested supervisor starts a whole new subtree, it does
    # not resume the dead one.
    method _duplicate () {
        my $copy = ref($self)->new( strategy => $strategy, max_restarts => $max_restarts, within => $within );
        for my $spec (@specs) {
            my ( $thing, %opts ) = @$spec;
            if ( ref $thing ne 'CODE' ) {
                my $inst = $thing;
                $thing = $inst->isa('Acme::Parataxis::Supervisor') ? sub { $inst->_duplicate } : sub { $inst->respawn };
            }
            $copy->supervise( $thing, %opts );
        }
        return $copy;
    }

    # Start the tree and supervise it until stop() is called or the restart budget runs out.
    # Returns normally after a stop(); dies with Acme::Parataxis::Error::Supervisor when the budget
    # is exhausted. Either way every child is stopped and drained before this returns, so no fiber
    # of the tree outlives it.
    method run () {
        croak 'Supervisor->run() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        croak 'Supervisor->run() requires at least one supervised child' unless @children;
        croak 'Supervisor->run() may only be called once' if $started;
        $started = $running = true;
        my $ok = 1;
        my $err;
        try { $self->_supervise_loop } catch ($e) {
            $ok  = 0;
            $err = $e
        }
        $self->_shutdown;
        $running = false;
        die $err unless $ok;
        return $self;
    }

    # Ask the tree to shut down. Safe to call from any fiber, including from inside a child: it
    # never parks, so it cannot re-enter the scheduler halfway through tearing the tree down. The
    # supervision loop wakes on the marker below and stops restarting anything.
    method stop () {
        return $self if $stopping;
        $stopping = true;
        $deaths->put( ['WAKE'] );
        $self->_stop_children;
        return $self;
    }

    # Bring the whole tree down: ask every child that is still running to stop, then wait for each
    # of them to report its death. Waiting matters - it is what makes "the live fiber count returns
    # to baseline once run() returns" true instead of a race.
    method _shutdown () {
        $stopping = true;
        $self->_stop_children;
        while ( grep { $_->{pending} } @children ) {
            my $ev = $deaths->get;
            next if @$ev == 1;    # wake marker
            my ( $child, $token ) = @$ev;
            next unless ref $child eq 'HASH' && defined $child->{token} && $child->{token} == $token;
            $child->{pending} = 0;
        }
        return;
    }

    method _stop_children () {
        for my $child (@children) {
            next unless $child->{pending};    # not running: never started, already reported, or failed to start
            my $inst = $child->{instance} or next;
            try { $inst->stop } catch ($e) {
                warn "Acme::Parataxis::Supervisor: stopping child '$child->{name}' failed: $e"
            }
        }
        return;
    }

    method _supervise_loop () {
        $self->_spawn($_) for @children;
        while ( !$stopping ) {
            my $ev = $deaths->get;
            last if $stopping;
            next if @$ev == 1;    # wake marker from a stop() already seen above
            my ( $child, $token, $err ) = @$ev;
            next unless ref $child eq 'HASH' && defined $child->{token} && $child->{token} == $token;

            # The current instance really died. An expected stop cannot land here: stop() sets the
            # flag first, and a sibling replaced during a OneForAll/RestForOne restart reports under
            # the token it was started with, which no longer matches.
            $child->{pending} = 0;
            my $reason = defined $err ? $err : "child '$child->{name}' exited cleanly";
            my $now    = time;
            @budget = grep { $now - $_->[0] < $within } @budget;    # within => 0 keeps nothing: the budget never trips
            if ( @budget >= $max_restarts ) {
                my @failures = ( ( map { $_->[2] } @budget ), $reason );
                die Acme::Parataxis::Error::Supervisor->new(
                    failures => \@failures,
                    primary  => $reason,
                    child    => $child->{name},
                    strategy => $strategy,
                    restarts => $max_restarts
                );
            }
            push @budget, [ $now, $child->{name}, $reason ];
            $self->_apply_strategy($child);
        }
        return;
    }

    # Which children a death of $dead drags down with it, in start order. Restarting in start
    # order keeps RestForOne's suffix (and OneForAll's set) coming back up the way it went down.
    method _apply_strategy ($dead) {
        my @set = grep { $strategy eq 'OneForOne' ? $_ == $dead : $strategy eq 'OneForAll' ? 1 : $_->{index} >= $dead->{index} }
            sort { $a->{index} <=> $b->{index} } @children;
        $self->_restart_child($_) for @set;
        return;
    }

    # Replace one child's instance: ask the old one to stop if it has not already gone, then start
    # a fresh one. The old instance's death report still arrives, but under the token it was
    # started with, so it is dropped instead of being mistaken for a new crash.
    method _restart_child ($child) {
        if ( $child->{pending} && defined $child->{instance} ) {
            try { $child->{instance}->stop }
            catch ($e) {
                warn "Acme::Parataxis::Supervisor: restarting '$child->{name}' but stopping the old instance failed: $e"
            }
        }
        $self->_spawn($child);
        $child->{restarts}++;    # every child this strategy replaced counts, not only the one that died
        return;
    }

    # Start one child's next instance and arrange for exactly one death report for it, whatever
    # goes wrong: a factory that dies, a factory returning the wrong thing (a programming error,
    # so it propagates out of run()), a hook that cannot be installed, or the instance dying later.
    method _spawn ($child) {
        my ( $inst, $err, $ok );

        # The first start adopts the instance supervise() was handed (an actor already running, or
        # a nested supervisor already built); every start after that goes through the factory, which
        # is what makes a restart a fresh instance instead of a second run of a dead one.
        if ( defined $child->{initial} ) { ( $inst, $ok ) = ( delete $child->{initial}, 1 ) }
        else {
            $ok = 1;
            try { $inst = $child->{factory}->() } catch ($e) {
                $ok  = 0;
                $err = $e
            }
        }
        croak "Supervisor child '$child->{name}' factory must return an Acme::Parataxis::Actor or an Acme::Parataxis::Supervisor"
            if $ok && ( !blessed($inst) || ( !$inst->isa('Acme::Parataxis::Actor') && !$inst->isa('Acme::Parataxis::Supervisor') ) );
        my $token = [];
        $child->{token}    = $token;
        $child->{instance} = $inst;
        $child->{pending}  = 1;
        if ( !defined $inst ) {    # the factory itself died: that is the child's death
            $deaths->put( [ $child, $token, $err ] );
            return;
        }
        my $hooked = 1;
        my $hook_err;
        try {
            if ( $inst->isa('Acme::Parataxis::Supervisor') ) {
                fiber {
                    my $ok2 = 1;
                    my $run_err;
                    try { $inst->run } catch ($e) {
                        $ok2     = 0;
                        $run_err = $e
                    }
                    $self->_report( $child, $token, $ok2 ? undef : $run_err );
                };
            }
            else {
                $inst->on_death( sub ( $actor, $e ) { $self->_report( $child, $token, $e ) } );
            }
        }
        catch ($e) { $hooked = 0; $hook_err = $e }
        unless ($hooked) {    # could not watch it (e.g. no fiber slot left): report and give up on it
            $child->{instance} = undef;
            $deaths->put( [ $child, $token, $hook_err ] );
        }
        return;
    }

    method _report ( $child, $token, $err ) {
        $deaths->put( [ $child, $token, $err ] );
        return;
    }

    # introspection
    method children () {
        map { $_->{name} } @children;
    }

    method child ($name) {
        croak 'Supervisor->child() requires a child name' unless defined $name && !ref $name;
        my ($child) = grep { $_->{name} eq $name } @children;
        croak "Supervisor->child(): no supervised child named '$name'" unless $child;
        return $child->{instance};
    }

    # Restarts of one child, or of the whole tree when called without a name.
    method restarts ( $name = undef ) {
        unless ( defined $name ) {
            my $total = 0;
            $total += $_->{restarts} for @children;
            return $total;
        }
        my ($child) = grep { $_->{name} eq $name } @children;
        croak "Supervisor->restarts(): no supervised child named '$name'" unless $child;
        return $child->{restarts};
    }
};
#
1;
