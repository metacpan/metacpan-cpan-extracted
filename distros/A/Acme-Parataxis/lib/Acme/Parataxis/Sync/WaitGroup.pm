use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Sync::WaitGroup v0.1.1 : isa(Acme::Parataxis::Sync) {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $count : reader : param //= 0;    # outstanding jobs; wait() unblocks once this hits zero
    field @waiters;                         # fiber ids parked in wait(), FIFO

    method add ($n) {
        croak 'WaitGroup add() requires an integer' unless defined $n && !ref $n && $n =~ /\A-?\d+\z/;
        $count += $n;
        croak 'WaitGroup counter would become negative' if $count < 0;
        $self->_release                                 if $count == 0;
        return 1;
    }
    method done { $self->add(-1) }

    # Park until the counter reaches zero. Returns immediately when it already has.
    method wait {
        my $fid = $self->_fid('WaitGroup waits must occur inside a scheduled fiber');
        while ( $count > 0 ) {
            push @waiters, $fid;
            $self->_park( 'WaitGroup wait', sub { $self->remove_waiter($fid) } );
        }
        return 1;
    }

    method _release {    # counter just hit zero: wake everyone parked in wait()
        my @w = @waiters;
        @waiters = ();
        $self->_wake($_) for @w;
    }
    method remaining {$count}
    method waiters   { scalar @waiters }

    method remove_waiter ($fid) {
        my $before = @waiters;
        @waiters = grep { $_ != $fid } @waiters;
        return $before - @waiters;
    }
};
#
1;
