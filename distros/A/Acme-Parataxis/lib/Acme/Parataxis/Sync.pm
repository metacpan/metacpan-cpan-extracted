use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Sync v0.1.1 {
    use Acme::Parataxis;
    use Carp qw[croak];

    # Base class for the synchronization-primitive family (Mutex, WaitGroup, Barrier, Once).
    # Shared plumbing: resolving the current fiber id, parking with a wake deregistration, and waking a parked fiber.
    method _fid ($what) {
        my $fid = Acme::Parataxis->current_fid;
        croak $what if $fid < 0;
        return $fid;
    }

    # Park the current fiber on this primitive. $dereg unregisters the waiter when the park is interrupted, so a
    # cancelled wait never leaves a stale id that a later wake could fire at a reused fiber. Level 2 attributes the
    # wait_reason to the caller of the subclass method (one frame down from here).
    method _park ( $reason, $dereg = undef ) { Acme::Parataxis::_park( $reason, 2, $dereg ) }

    # Wake one waiter via the scheduler, skipping ids whose fiber has gone away.
    method _wake ($waiter) { Acme::Parataxis::_scheduler_enqueue_by_id($waiter) if defined Acme::Parataxis->by_id($waiter) }
};
#
1;
