use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Driver v0.1.3 {
    use Carp qw[croak];
    use builtin qw[blessed];

    # Base class for the event-loop drivers behind Acme::Parataxis->attach_loop(). A driver wraps an existing CPAN
    # event loop (Mojo::IOLoop, IO::Async::Loop, ...) so that await_read / await_write / await_sleep are serviced by
    # epoll/kqueue/select readiness instead of burning an OS-thread pool job per filehandle. The scheduler keeps its
    # own park/wake machinery; the driver only *tells* the loop which filehandles to watch and hands control to the
    # loop when every fiber is parked.
    #
    # Subclasses implement the loop-specific bit (watch_read/watch_write/unwatch/timer/cancel_timer/drive/poll_ready);
    # this base owns the bookkeeping -- which watches and timers are still live -- that the scheduler uses to decide
    # whether the loop still needs control (pending) and to tear the whole thing down between runs (reset).
    field %watches;    # fileno => the filehandle being watched (one *multi-direction* slot per filehandle)
    field %timers;     # opaque timer id => 1, ids handed back by the subclass constructor

    # True while this driver still has registered watches or timers. The scheduler's idle branch hands control to the
    # loop only when this is true; with nothing pending a run would otherwise block forever in the loop instead of
    # deadlock-detecting.
    method pending { return scalar( keys %watches ) + scalar( keys %timers ) }

    # Unwind every watch and timer this driver registered. Called by run() on teardown and by detach_loop(), so a
    # stale listener socket or deadline timer from an exited run can never leave the next run blocked in the loop.
    method reset {
        my @fhs = values %watches;
        $self->unwatch($_) for @fhs;

        # unwatch() matches on identity, so it cannot find the slot of a handle that was closed while it was being
        # watched - fileno() is undef by then, and there is no number left to look up. Such a slot would survive
        # every reset, leaving pending() permanently true so the next run keeps handing control to a loop with
        # nothing to do. Unwinding everything is the whole contract of this method, so empty the tables outright
        # rather than trusting the walk above to have reached every entry.
        %watches = ();
        my @ids = keys %timers;
        $self->cancel_timer($_) for @ids;
        %timers = ();
        return 1;
    }

    # -- shared bookkeeping helpers. Subclasses call these when they (de)register with the underlying loop. --
    # The key is the descriptor number, but a number is not an identity: the OS recycles it the moment a handle is
    # closed, so a slot can outlive the handle it was made for and be handed on to an unrelated one. The slot's
    # value is that handle, held here, so refaddr() is a stable identity for as long as the slot exists, and every
    # lookup compares the handle it was given against the handle actually stored. Believing the number alone is how
    # a fiber gets parked on a registration that will never fire: the new handle sees has_watch() true for a slot it
    # never made, the subclass skips registering it with the loop, and the slot's callback is never reached.
    method _track_watch ($fh) {
        my $fd = fileno($fh);
        $watches{$fd} = $fh;    # a slot keyed to a recycled number is replaced, releasing the stale handle
        return $fd;
    }

    method _untrack_watch ($fh) {
        my $fd = fileno($fh);
        return 0 unless defined $fd;
        my $held = $watches{$fd};
        return 0 unless defined $held;
        return 0 unless builtin::refaddr($held) == builtin::refaddr($fh);    # somebody else's slot
        delete $watches{$fd};
        return 1;
    }

    method _track_timer ($id) {
        $timers{$id} = 1;
        return $id;
    }

    method _untrack_timer ($id) {
        return 0 unless exists $timers{$id};
        delete $timers{$id};
        return 1;
    }

    # True when $fh already has a live watch slot in this driver (both directions share one slot per filehandle).
    method has_watch ($fh) {
        my $fd = fileno($fh);
        return 0 unless defined $fd;
        my $held = $watches{$fd};
        return 0 unless defined $held;
        return builtin::refaddr($held) == builtin::refaddr($fh) ? 1 : 0;
    }
    method watch_count () { return scalar( keys %watches ) }
    method timer_count () { return scalar( keys %timers ) }

    # subclass interface
    method watch_read( $fh, $cb )  {...}    # call $cb->() when $fh becomes readable
    method watch_write( $fh, $cb ) {...}    # call $cb->() when $fh becomes writable
    method unwatch($fh)            {...}    # stop watching $fh (both directions), 0 if nothing was watched
    method timer( $ms, $cb )       {...}    # call $cb->() after $ms millseconds; returns an opaque id
    method cancel_timer($id)       {...}    # cancel a pending timer, 0 if unknown/already fired
    method drive()                 {...}    # run the loop until at least one event fires (may block)

    # One readiness pass, and the scheduler expects it back promptly -- it only reaches this on the pass where pool jobs
    # are still in flight and nothing is runnable, so a version that waits turns a long driver timer (a with_timeout
    # deadline, an await_read timeout) into a stall on that loop. Whether a loop can honour that is up to the loop:
    # IO::Async's loop_once(0) returns at once and still fires a due timer, while Mojo's one_tick takes no timeout at
    # all and always waits for the earliest registered timer, so Driver::Mojo's poll_ready is the same call as its
    # drive(). Subclass this only if your loop can do a genuinely non-blocking pass.
    method poll_ready() {...}    # run the loop's readiness pass; expected not to block

    # Wrap (or pass through) an event loop object as a Driver. attach_loop() routes everything through here, so callers
    # may hand in a Mojo::IOLoop (or Mojo::Reactor) or an IO::Async::Loop and get the right reference driver for free.
    # A plain package sub declared outside the class block, since it returns a driver rather than dispatching on one.
    # Called as Acme::Parataxis::Driver::wrap($loop).
    sub wrap ($loop) {
        Carp::croak 'wrap() requires an event-loop object' unless builtin::blessed($loop);
        return $loop if $loop->isa('Acme::Parataxis::Driver');
        my $pkg = ref $loop;
        if ( $pkg =~ /^Mojo::/ || $loop->isa('Mojo::IOLoop') || $loop->isa('Mojo::Reactor') ) {
            require Acme::Parataxis::Driver::Mojo;
            return Acme::Parataxis::Driver::Mojo->new( loop => $loop );
        }
        if ( $pkg =~ /^IO::Async::/ ) {
            require Acme::Parataxis::Driver::IOAsync;
            return Acme::Parataxis::Driver::IOAsync->new( loop => $loop );
        }
        Carp::croak "wrap() does not know how to drive a $pkg event loop";
    }
};
#
1;
