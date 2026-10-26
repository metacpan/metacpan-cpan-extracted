use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
#
# Structured concurrency: an enclosed block spawns child fibers that are all guaranteed to
# finish before the enclosing nursery returns, and that are all cancelled the moment any
# one of them fails. `Acme::Parataxis->nursery( sub ($n) { ... } )` builds one of these,
# runs the block in the calling fiber (the parent), joins every child, and rethrows the
# first failure as an Acme::Parataxis::Error::Nursery whose ->failures lists every child
# error (Principle 4: a plain aggregate error, no Java ExceptionGroup).
class Acme::Parataxis::Nursery v0.1.1 {
    use Acme::Parataxis;
    use Acme::Parataxis::CancellationToken;
    use Carp qw[croak];

    # The token that cancels every enrolled child. Cancelling it from user code (or passing
    # it to a nested with_timeout) cancels the whole nursery, as if a sibling had failed.
    field $token : reader : param = Acme::Parataxis::CancellationToken->new;

    # Every enrolled child, in spawn order. Kept alive until the join so no child can be
    # destroyed (or orphaned) before the nursery has drained it.
    field @children;

    # Spawn a child fiber enrolled in this nursery. The child parks once at birth instead of
    # running inline, so a failure in its very first statement surfaces through the scheduler
    # (where the nursery can observe and aggregate it) rather than being thrown into the
    # block. Only children created through ->spawn are aggregated: a bare spawn/fiber inside
    # the block is an independent fiber the block owns itself.
    method spawn ($code) {
        croak 'Nursery::spawn() requires a CODE ref' unless ref $code eq 'CODE';
        croak 'Nursery::spawn() must be called from inside a scheduled fiber' if Acme::Parataxis->current_fid < 0;
        my $tok   = $token;
        my $child = Acme::Parataxis->spawn(
            sub {
                $tok->register;
                Acme::Parataxis->yield;    # birth park: this run never happens inline into the parent
                my $rv;
                my $err;
                try { $rv = $code->() } catch ($e) {
                    $err = $e
                }
                $tok->unregister;
                die $err if $err;
                return $rv;
            }
        );
        $child->on_ready( sub { $self->_observe( $_[0] ) } );
        push @children, $child;
        return $child;
    }

    # Fires the moment an enrolled child dies. Prompt sibling cancellation: interrupt every
    # other child still parked, so each throws Error::Cancelled at its next park re-entry and
    # unwinds; their errors land in the join's failure list. A natural completion is not a
    # failure and leaves the siblings alone.
    method _observe ($child) {
        return unless defined $child->error;
        $token->cancel;
    }

    # Await every child until it is done and reap its C coroutine, so nothing is left running
    # on any exit path and even a still-referenced child shell cannot leak a live fiber.
    # Returns the observed child errors (natural failures plus the Error::Cancelled unwinds of
    # the siblings they cancelled).
    #
    # If the *parent* is interrupted while parked in a child's await (e.g. an enclosing
    # with_timeout fired its deadline mid-join), that is not a child failure: the remaining
    # children are cancelled and drained, and the parent's own error is propagated.
    method _join () {
        for my $child (@children) {
            next if $child->is_done;
            my $ok = 1;
            my $e;
            try { $child->await } catch ($caught) {
                $ok = 0;
                $e  = $caught
            }
            if ($ok) {
                $child->is_done;
                next;
            }

            # If the child finished/died, its error will be aggregated below.
            next if $child->is_done;

            # The parent was interrupted mid-await: cancel siblings and drain.
            warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d join got parent-interrupt error=%s site=%s\n", ( time - $^T ) * 1000,
                Acme::Parataxis::current_fid, ref( $e || '' ) || "plain:$e", "$e"
                if $ENV{PARATAXIS_TRACE};
            $token->cancel;
            for my $c (@children) {
                next if $c->is_done;

                # Deliberately a *different* variable: $e is still the parent-interrupt error that
                # gets rethrown below, and a drain failure must not overwrite it.
                try { $c->await } catch ($drain_err) {
                }
                $c->is_done;
            }
            warn sprintf "PARATAXIS_TRACE t=%.0fms fid=%d join draining done, rethrowing error=%s\n", ( time - $^T ) * 1000,
                Acme::Parataxis::current_fid, ref( $e || '' ) || "plain:$e"
                if $ENV{PARATAXIS_TRACE};
            die $e;
        }
        return grep { defined $_ } map { $_->error } @children;
    }
};
#
1;
