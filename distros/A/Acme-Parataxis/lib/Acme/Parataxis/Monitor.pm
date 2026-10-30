use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';

# A monitor is pure observation, like an Erlang monitor: it resolves exactly once, when the
# target fiber exits, to undef for a clean end or to the fiber's death error for a crash. It
# rides the target's existing on_ready/on_death slot, so it needs no scheduler change and
# never owns the target (no stop, no join-without-error semantics). Watching an already-dead
# target fires immediately, because the underlying Future resolves inline during construction
# (the target parameter's on_ready hook fires right there).
#
# The target is held strongly so a monitor never loses its subject; reapability is about the
# C coroutine slot (driven by the fiber's own completion), which the monitor cannot delay.
# The reverse edge is cut: the completion callback captures the monitor weakly, so dropping
# a monitor lets it (and its strong target ref) dissolve instead of lingering in the target's
# callback list.
class Acme::Parataxis::Monitor v0.1.3 {
    use Acme::Parataxis;
    use Acme::Parataxis::Future;
    use Carp    qw[croak];
    use builtin qw[blessed weaken];
    field $target : param = undef;    # the watched fiber/future/actor object; a fiber id is resolved to its object first
    field $fid    : param = undef;    # optionally supplied watch target by id instead of by object
    field $future;                    # the single-resolution future that backs ->await/->result/->is_ready
    ADJUST {
        croak 'Monitor->new() takes a target or a fid, not both' if defined $target && defined $fid;
        if ( defined $fid ) {
            croak "Monitor->new() expects a numeric fiber id (got '$fid')" unless $fid =~ /^-?\d+$/;
            $target = Acme::Parataxis->by_id( 0 + $fid );
            croak "Monitor->new() couldn't find a fiber with id $fid" unless defined $target;
        }
        croak 'Monitor->new() requires a target to watch'                          unless defined $target;
        croak 'Monitor->new() requires a blessed target (fibers, futures, actors)' unless blessed $target;
        if ( !$target->can('on_ready') && !$target->can('on_death') ) {
            croak 'Monitor->new() cannot watch this target: it has neither on_ready() (fibers, futures) nor on_death() (actors)';
        }
        $fid //= $target->can('fid') ? $target->fid : undef;
        $future = Acme::Parataxis::Future->new;

        # The reverse edge is cut: the target's callback list holds only this weak copy, so a
        # dropped monitor (and its strong target ref) dissolves instead of lingering there.
        my $weak = $self;
        weaken $weak;
        if ( $target->can('on_ready') ) {
            $target->on_ready( sub { $weak->_resolve( $weak->target->error ) if $weak } );
        }
        else {
            $target->on_death( sub { $weak->_resolve( $_[1] ) if $weak } );
        }
    }

    # Resolve exactly once. $err is the target's death error, or undef for a clean end; it becomes
    # the monitor's *result* (never set_error), so ->await/->result return it instead of throwing.
    method _resolve ($err) {
        return $self if $future->is_ready;
        $future->set_result($err);
        return $self;
    }
    method await ()    { $future->await }                                 # parks until the target exits
    method result ()   { $future->result }                                # the resolution value; croaks until ready
    method error ()    { $future->is_ready ? $future->result : undef }    # death error (or undef), ready or not
    method is_ready () { $future->is_ready }
    method is_done ()  { $future->is_ready }                              # resolved == done, mirroring the fiber-side naming
    method target ()   {$target}                                          # the watched fiber/future/actor object
    method fid ()      {$fid}                                             # the target's fiber id at watch time (undef for non-fiber targets)

    method on_ready ($cb) {
        croak 'on_ready() requires a CODE ref' unless ref $cb eq 'CODE';
        my $weak = $self;
        weaken $weak;
        $future->on_ready( sub { $cb->($weak) if $weak } );               # hand the caller the monitor, not the inner future
        return $self;
    }
};
#
1;
