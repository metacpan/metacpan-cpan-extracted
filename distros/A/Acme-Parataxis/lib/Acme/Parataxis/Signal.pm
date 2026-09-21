use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
#
class Acme::Parataxis::Signal v0.1.0 {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $count : reader : param //= true;    # true if a send is pending
    field @waiters;                            # fiber ids (integers) or callback coderefs. FIFO

    method _wake_one () {
        my $waiter = shift @waiters;
        $count = false;                        # a woken waiter consumes the signal
        if ( ref $waiter eq 'CODE' ) { $waiter->() }
        else {
            Acme::Parataxis::_scheduler_enqueue_by_id($waiter);
        }
        $waiter;
    }

    method send () {    # Wake up one waiter, or remember the signal if nobody is waiting.
        if   (@waiters) { $self->_wake_one }
        else            { $count = true }      # remember the signal
        return true;
    }

    method broadcast {                         # Wake up all waiters.  If nobody is waiting the signal is lost.
        my $n = scalar @waiters;               # fixed wake budget, like coro_signal_wake
        $count = false;                        # signal lost if nobody is waiting
        $self->_wake_one while $n-- > 0 && @waiters;
        return true;
    }

    method wait ( $arg //= () ) {              # Returns true when at least one fiber is currently waiting on the signal.
        if ( defined $arg ) {
            push @waiters, $arg;               # callback form
            $self->send if $count;             # already signalled: fire now
            return;
        }
        if ($count) {
            $count = false;                    # consume the remembered signal
            return;
        }
        my $fid = Acme::Parataxis->current_fid;
        croak 'Signal waits must occur inside a scheduled fiber' if $fid < 0;
        push @waiters, $fid;
        Acme::Parataxis->yield('WAITING');
        return;
    }
    method awaited { return scalar @waiters }    # 0 when nobody is waiting
};
#
1;
