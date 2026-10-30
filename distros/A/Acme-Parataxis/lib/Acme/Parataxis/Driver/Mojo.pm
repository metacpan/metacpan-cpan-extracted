use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Driver::Mojo v0.1.3 : isa(Acme::Parataxis::Driver) {
    use Carp qw[croak];
    use builtin qw[blessed];

    # Drives readiness through a Mojo::IOLoop. The loop and Parataxis cooperate: Mojo never runs Parataxis callbacks
    # and Parataxis never runs Mojo callbacks; the reactor simply collects fd events and the tokencallback tells the
    # scheduler which fibers to resume. The passed $loop may itself be a Mojo::Reactor (anything with the reactor
    # API (io/watch/remove/timer/one_tick)) so a worker's own mini-loop can be run by Parataxis too.
    field $loop : param;
    field $reactor;
    field %read_cb;     # fileno => coderef
    field %write_cb;    # fileno => coderef
    ADJUST {
        croak 'Acme::Parataxis::Driver::Mojo requires a Mojo::IOLoop (or a Mojo::Reactor)' unless blessed($loop);
        $reactor = $loop->can('reactor') ? $loop->reactor : $loop;
        my $has_tick = 0;
        if ( defined $reactor ) {
            try { $has_tick = $reactor->can('one_tick') } catch ($e) {
            }    # can() itself may throw
        }
        croak 'Acme::Parataxis::Driver::Mojo requires a reactor with a one_tick() method' unless $has_tick;
    }
    method watch_read  ( $fh, $cb ) { $self->_watch( $fh, 'r', $cb ) }
    method watch_write ( $fh, $cb ) { $self->_watch( $fh, 'w', $cb ) }

    # Mojo's reactor allows exactly one io() watcher per filehandle; directional interest is expressed through
    # watch($fh, $read, $write). So we install the io() callback once per filehandle (if not already there) and flip
    # the desired mask on every registration.
    method _watch ( $fh, $dir, $cb ) {
        my $fd = fileno($fh);
        croak 'Mojo driver cannot watch a closed filehandle' unless defined $fd;

        # has_watch() compares handles, not descriptor numbers, so a false here means this handle has no slot of its
        # own... it is new to us, or the number it was just given belonged to a closed handle we were still holding.
        # Either way the callbacks keyed to this number are not this handle's, and a stale direction left behind is
        # live: a handle that only ever asked to read would have POLLOUT set from the previous owner and its dead
        # write callback fired. Clear the slot before claiming it.
        my $fresh = !$self->has_watch($fh);
        if ($fresh) {
            delete $read_cb{$fd};
            delete $write_cb{$fd};
        }
        if   ( $dir eq 'r' ) { $read_cb{$fd}  = $cb }
        else                 { $write_cb{$fd} = $cb }
        if ($fresh) {
            try { $fh->blocking(0) } catch ($e) {
            }    # a handle that refuses is still worth watching
            $reactor->io(
                $fh,
                sub ( $reactor, $writable ) {
                    if   ($writable) { $write_cb{$fd}->() if $write_cb{$fd} }
                    else             { $read_cb{$fd}->()  if $read_cb{$fd} }
                }
            );
        }
        $self->_track_watch($fh);
        $reactor->watch( $fh, $read_cb{$fd} ? 1 : 0, $write_cb{$fd} ? 1 : 0 );
        return $fh;
    }

    method unwatch ($fh) {
        my $fd = fileno($fh);
        return 0 unless defined $fd && $self->has_watch($fh);
        delete $read_cb{$fd};
        delete $write_cb{$fd};
        $self->_untrack_watch($fh);
        try { $reactor->remove($fh) } catch ($e) {
        }    # already gone from the reactor's point of view
        return 1;
    }

    method timer ( $ms, $cb ) {
        croak 'Mojo driver timer requires a positive delay' unless defined $ms && $ms > 0;
        my $id;
        $id = $reactor->timer(
            $ms / 1000,
            sub {
                $self->_untrack_timer($id);
                $cb->();
            }
        );
        $self->_track_timer($id);
        return $id;
    }

    method cancel_timer ($id) {
        return 0 unless $self->_untrack_timer($id);
        $reactor->remove($id);
        return 1;
    }
    method drive ()      { $reactor->one_tick; return 1 }
    method poll_ready () { $reactor->one_tick; return 1 }
};
#
1;
