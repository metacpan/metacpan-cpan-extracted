use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Semaphore v0.1.1 {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $count : reader : param //= 1;
    field @waiters : reader;    # fiber ids in FIFO order and re-enqueued via the scheduler when woken

    method _block_until_available ( $reason = 'Semaphore down', $level = 2 )
    {                           # Park the current fiber until a permit is available then recheck the count
        while ( $count <= 0 ) {
            my $fid = Acme::Parataxis->current_fid;
            croak 'Semaphore waits must occur inside a scheduled fiber' if $fid < 0;
            push @waiters, $fid;
            Acme::Parataxis::_park( $reason, $level, sub { $self->remove_waiter($fid) } );
        }
        1;
    }

    method down ( $reason = 'Semaphore down', $level = 2 ) {
        $self->_block_until_available( $reason, $level );
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
    method wait ( $reason = 'Semaphore down', $level = 2 ) { $self->_block_until_available( $reason, $level ) }

    method guard () {
        $self->down( 'Semaphore down', 3 );
        Acme::Parataxis::Semaphore::Guard->new( semaphore => $self );
    }

    method remove_waiter ($fid) {    # Unregisters a parked fiber id so a later up()/adjust() will not wake it.
        my $before = @waiters;
        @waiters = grep { $_ != $fid } @waiters;
        return $before - @waiters;
    }
};

# Util. A classic package, not feature::class: a perlclass 'method DESTROY' on a second class
# block in the same file crashes perl_clone on some perls (threads->create => access violation
# in Perl_newPADNAMEouter), and keep()/sync primitives must remain loadable pre-thread-create.
package Acme::Parataxis::Semaphore::Guard v0.1.1 {

    sub new ( $class, %args ) {
        return bless { semaphore => $args{semaphore} }, $class;
    }

    sub DESTROY {
        my $self = shift;
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        $self->{semaphore}->up;
    }
};
#
1;
