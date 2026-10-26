use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
class Acme::Parataxis::Sync::Mutex v0.1.1 : isa(Acme::Parataxis::Sync) {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $owner : reader;    # fiber id holding the lock; undef when free
    field @waiters;           # fiber ids waiting to lock, FIFO

    # Acquire the lock, parking until it is handed over. The lock is not reentrant: a fiber that already holds it croaks.
    method lock {
        my $fid = $self->_fid('Mutex locks must occur inside a scheduled fiber');
        if ( !defined $owner ) { $owner = $fid; return 1 }
        croak 'Mutex is not reentrant: this fiber already holds the lock' if $owner == $fid;
        push @waiters, $fid;
        $self->_park(
            'Mutex lock',
            sub {
                # An unlock() may have handed the lock to us just as an interrupt (deadline/cancel) fired. That hand-off
                # is never collected -- the interrupt throws before lock() returns -- so pass it on so ownership is not
                # left stranded on a fid that is about to die (and later be reused).
                if ( defined $owner && $owner == $fid ) {
                    $owner = undef;
                    $self->_serve;
                }
                $self->remove_waiter($fid);
            }
        );
        return 1;    # unlock() handed the lock to us before waking us
    }

    # Non-blocking acquisition; returns false instead of parking when the lock is held.
    method try_lock {
        my $fid = $self->_fid('Mutex locks must occur inside a scheduled fiber');
        return 0                                                          if defined $owner && $owner != $fid;
        croak 'Mutex is not reentrant: this fiber already holds the lock' if defined $owner;
        $owner = $fid;
        return 1;
    }

    # Release the lock to the next waiter (or free it). Only the owning fiber may release.
    method unlock {
        my $fid = $self->_fid('Mutex unlocks must occur inside a scheduled fiber');
        croak 'Mutex is not locked'                              unless defined $owner;
        croak 'Mutex release from a fiber that is not the owner' unless $owner == $fid;
        $self->_serve;
        return 1;
    }

    # Hand the lock to the next living waiter, or free it. owner is set before the waiter is woken so nobody else can
    # steal the lock between the hand-off and the waiter running to collect it.
    method _serve {
        my $next;
        while (@waiters) {
            my $waiter = shift @waiters;
            next unless defined Acme::Parataxis->by_id($waiter);
            $next = $waiter;
            last;
        }
        $owner = $next;    # hand-off is atomic: nobody else can steal it before the waiter runs
        Acme::Parataxis::_scheduler_enqueue_by_id($next) if defined $next;
        return 1;
    }

    # Return a Scope::Guard-style object that unlocks on destruction.
    method guard {
        $self->lock;
        Acme::Parataxis::Sync::Mutex::Guard->new( mutex => $self );
    }
    method waiters { scalar @waiters }

    method remove_waiter ($fid) {    # unregister a parked waiter (used by the lock park's interruption path)
        my $before = @waiters;
        @waiters = grep { $_ != $fid } @waiters;
        return $before - @waiters;
    }
};

# Util. A classic package, not feature::class: a perlclass 'method DESTROY' is one trigger of the perl_clone access
# violation behind threads->create on some 5.42.x builds (Acme::Parataxis::Blocking's spawn_blocking), so guard classes
# are kept as classic blessed packages. Note: the Sync::* namespaces themselves still hit a separate, name-dependent
# clone crash on affected perls regardless of this - see Acme::Parataxis::Blocking's pod warning.
package Acme::Parataxis::Sync::Mutex::Guard v0.1.1 {

    sub new ( $class, %args ) {
        return bless { mutex => $args{mutex} }, $class;
    }

    sub DESTROY {
        my $self = shift;
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        $self->{mutex}->unlock;
    }
}
#
1;
