use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
class Acme::Parataxis::Future v0.1.0 {
    use Carp qw[croak];
    field $is_ready : reader = 0;
    field $result;
    field $error;
    field @callbacks;
    field @waiters;

    method result () {    # Returns the task result immediately. Croaks if the future is not yet ready or failed.
        croak 'Future not ready' unless $is_ready;
        croak $error if defined $error;
        return $result;
    }

    method set_result ($val) {
        die 'Future already ready' if $is_ready;
        $result   = $val;
        $is_ready = 1;
        $_->($self) for @callbacks;
        $self->_wake_waiters;
    }

    method set_error ($err) {
        die 'Future already ready' if $is_ready;
        $error    = $err;
        $is_ready = 1;
        $_->($self) for @callbacks;
        $self->_wake_waiters;
    }

    method clear_result () {
        $result    = undef;
        $error     = undef;
        $is_ready  = 0;
        @callbacks = ();
        @waiters   = ();
    }

    method on_ready ($cb) {
        if   ($is_ready) { $cb->($self) }
        else             { push @callbacks, $cb }
    }

    method await () {

        # Suspends the current fiber until the future is ready. Returns the result or dies if the task encountered an error.
        return $self->result if $is_ready;
        my $fid = Acme::Parataxis->current_fid;
        croak 'await() must be called from inside a scheduled fiber' if $fid < 0;
        push @waiters, $fid;
        Acme::Parataxis->yield('WAITING');
        $self->result;
    }

    method _wake_waiters () {
        return unless @waiters;
        Acme::Parataxis::_scheduler_enqueue_by_id($_) for @waiters;
        @waiters = ();
    }
};
#
1;
