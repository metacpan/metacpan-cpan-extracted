use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Sync::Barrier v0.1.1 : isa(Acme::Parataxis::Sync) {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $parties : reader : param;    # fibers required per phase
    field $remaining : reader;          # arrivals still needed in the current phase
    field $generation = 0;              # phase counter, bumped on every release
    field @waiters;                     # fiber ids that arrived before the last arrival, FIFO
    ADJUST {
        croak 'Barrier requires a positive number of parties' if $parties < 1;
        $remaining = $parties;
    }

    # Arrive at the barrier and park until $parties fibers have arrived in this phase. The last arrival releases
    # everyone (including itself) and bumps the phase, so a fresh phase starts immediately afterward.
    method arrive_and_wait {
        my $fid = $self->_fid('Barrier waits must occur inside a scheduled fiber');
        if ( --$remaining <= 0 ) {
            $generation++;
            $remaining = $parties;
            my @w = @waiters;
            @waiters = ();
            $self->_wake($_) for @w;
            return 1;
        }
        push @waiters, $fid;
        $self->_park( 'Barrier arrive', sub { $self->remove_waiter($fid) } );
        return 1;
    }
    method waiters { scalar @waiters }

    method remove_waiter ($fid) {
        my $before = @waiters;
        @waiters = grep { $_ != $fid } @waiters;
        return $before - @waiters;
    }
};
#
1;
