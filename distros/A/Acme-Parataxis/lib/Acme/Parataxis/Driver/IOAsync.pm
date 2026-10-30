use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Driver::IOAsync v0.1.3 : isa(Acme::Parataxis::Driver) {
    use Carp qw[croak];
    use builtin qw[blessed];

    # Drives readiness through an IO::Async::Loop. IO::Async allows only one watch_io stanza per filehandle, but a
    # read and a write may be established as two separate watch_io() calls (IO::Async >= 0.805). To keep the one-slot
    # bookkeeping in the base class simple we always report both directions on unwatch; IO::Async tolerates canceling
    # a direction that was never requested. watch_time()/unwatch_time() back timer()/cancel_timer(), and loop_once()
    # (which also fires due timers) backs drive()/poll_ready().
    field $loop : param;    # an IO::Async::Loop (usually IO::Async::Loop::Select on Windows)
    field %read_cb;         # fileno => coderef
    field %write_cb;        # fileno => coderef
    ADJUST {
        croak 'Acme::Parataxis::Driver::IOAsync requires an IO::Async::Loop' unless blessed($loop) && $loop->isa('IO::Async::Loop');
    }
    method watch_read  ( $fh, $cb ) { $self->_watch( $fh, 'r', $cb ) }
    method watch_write ( $fh, $cb ) { $self->_watch( $fh, 'w', $cb ) }

    method _watch ( $fh, $dir, $cb ) {
        my $fd = fileno($fh);
        croak 'IOAsync driver cannot watch a closed filehandle' unless defined $fd;

        # As in Driver::Mojo: has_watch() compares handles rather than descriptor numbers, so a false here means this
        # handle owns no slot yet and any callbacks filed under this number belong to a handle that is gone. Clearing
        # them first keeps a recycled number from inheriting the previous owner's direction.
        if ( !$self->has_watch($fh) ) {
            delete $read_cb{$fd};
            delete $write_cb{$fd};
        }
        if   ( $dir eq 'r' ) { $read_cb{$fd}  = $cb }
        else                 { $write_cb{$fd} = $cb }
        $self->_track_watch($fh);
        my %params = ( handle => $fh );
        $params{on_read_ready}  = $read_cb{$fd}  if $read_cb{$fd};
        $params{on_write_ready} = $write_cb{$fd} if $write_cb{$fd};
        $loop->watch_io(%params);
        return $fh;
    }

    method unwatch ($fh) {
        my $fd = fileno($fh);
        return 0 unless defined $fd && $self->has_watch($fh);
        delete $read_cb{$fd};
        delete $write_cb{$fd};
        $self->_untrack_watch($fh);
        $loop->unwatch_io( handle => $fh, on_read_ready => 1, on_write_ready => 1 );
        return 1;
    }

    method timer ( $ms, $cb ) {
        croak 'IOAsync driver timer requires a positive delay' unless defined $ms && $ms > 0;
        my $id;
        $id = $loop->watch_time(
            after => $ms / 1000,
            code  => sub {
                $self->_untrack_timer($id);
                $cb->();
            }
        );
        $self->_track_timer($id);
        return $id;
    }

    method cancel_timer ($id) {
        return 0 unless $self->_untrack_timer($id);
        $loop->unwatch_time($id);
        return 1;
    }

    # loop_once(undef) blocks in select() until an event (IO or the earliest due timer) happens; loop_once(0) is a
    # non-blocking readiness pass that still fires any already-due timers.
    method drive ()      { $loop->loop_once(undef); return 1 }
    method poll_ready () { $loop->loop_once(0);     return 1 }
};
#
1;
