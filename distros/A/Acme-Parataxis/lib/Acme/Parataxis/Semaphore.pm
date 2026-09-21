use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
class Acme::Parataxis::Semaphore v0.1.0 {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $count : reader : param //= 1;
    field @waiters : reader;    # fiber ids in FIFO order and re-enqueued via the scheduler when woken

    method _block_until_available () {    # Park the current fiber until a permit is available then recheck the count
        while ( $count <= 0 ) {
            my $fid = Acme::Parataxis->current_fid;
            croak 'Semaphore waits must occur inside a scheduled fiber' if $fid < 0;
            push @waiters, $fid;
            Acme::Parataxis->yield('WAITING');
        }
        1;
    }

    method down () {
        $self->_block_until_available;
        $count--;
        1;
    }

    method try () {
        return 0 if $count <= 0;
        $count--;
        1;
    }

    method _wake_waiters ($budget) {    # Wakes up to $budget waiters, skipping stale (destroyed) fiber ids
        my $woken = 0;
        while ( @waiters && $woken < $budget ) {
            my $waiter = shift @waiters;
            next unless defined Acme::Parataxis->by_id($waiter);
            Acme::Parataxis::_scheduler_enqueue_by_id($waiter);
            $woken++;
        }
        $woken;
    }

    method up () {
        $count++;
        $self->_wake_waiters(1) if $count > 0;
        1;
    }

    method adjust ($diff) {
        $count += $diff;
        my $n       = $count;
        my $waiting = scalar @waiters;
        $n = $waiting if $waiting < $n;
        $self->_wake_waiters($n);
        1;
    }
    method wait () { $self->_block_until_available }

    method guard () {
        $self->down;
        Acme::Parataxis::Semaphore::Guard->new( semaphore => $self );
    }
};

class Acme::Parataxis::Semaphore::Guard {    # Util
    field $semaphore : param;

    method DESTROY {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        $semaphore->up;
    }
};
#
1;
