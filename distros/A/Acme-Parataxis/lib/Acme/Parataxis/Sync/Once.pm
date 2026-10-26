use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Sync::Once v0.1.1 : isa(Acme::Parataxis::Sync) {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $owner;                    # fiber id running the action; undef when idle
    field $done : reader = false;    # the action has completed (even if it died)
    field @waiters;                  # fiber ids parked until the action completes, FIFO

    # Run $code exactly once. The first fiber in executes it; concurrent callers park until it finishes and late
    # callers return immediately. If the action dies, that error propagates to the executing fiber only, the Once is
    # still marked done (matching sync.Once), and the parked waiters proceed.
    method do ($code) {
        croak 'Once::do requires a CODE reference' unless ref $code eq 'CODE';
        my $fid = $self->_fid('Once actions must run inside a scheduled fiber');
        return if $done;
        if ( defined $owner ) {
            croak 'Once::do is not reentrant: this fiber is already running the action' if $owner == $fid;
            push @waiters, $fid;
            $self->_park( 'Once init', sub { $self->remove_waiter($fid) } );
            return;    # waited out the runner: no value of our own
        }
        $owner = $fid;
        my $rv;
        my $err;
        try { $rv = $code->() } catch ($e) {
            $err = $e
        }
        $owner = undef;
        $done  = 1;
        my @w = @waiters;
        @waiters = ();
        $self->_wake($_) for @w;
        die $err if $err;
        return $rv;
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
