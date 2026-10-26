use v5.40;

package Acme::Parataxis::Compat v0.1.1 {
    use Errno       qw[EAGAIN EWOULDBLOCK];
    use IO::Handle  ();                       # loaded only: the overrides call IO::Handle::blocking() fully qualified
    use Carp        qw[croak];
    use Time::HiRes ();                       # loaded only: the overrides call Time::HiRes::time() fully qualified

    #
    # Transparent unblocking (CORE::GLOBAL overrides). This module is an opt-in
    # convenience: Acme::Parataxis->enable_transparent_unblocking() installs overrides
    # that make the blocking builtins `sleep`, `read` and `sysread` cooperative inside
    # scheduled fibers, and delegate to the raw CORE:: builtin everywhere else (top
    # level, foreign threads), so nothing outside the scheduler changes.
    #
    # The override subs are installed, not compiled with the module, so only code that
    # is *compiled after installation* is affected - exactly the gevent-style contract.
    # Every override calls the real builtin through its CORE:: name, so none of them can
    # recurse into themselves.
    #
    my $INSTALLED = 0;
    my @SAVED;    # [ name, saved-glob ] per installed override, for disable()

    # The readiness budget, in ms, that the read/sysread overrides give each await_read probe. A probe that comes
    # back short of it means a real wait timed out, so the override keeps waiting rather than block the process.
    my $PROBE_MS = 5000;

    # How much of that budget a probe has to burn before its -1 is read as "the handle is watchable, it just had
    # nothing to say" rather than "this platform cannot watch this handle at all". Win32's select() takes sockets
    # and nothing else, so a pipe or a regular file there answers -1 instantly, while a socket that truly timed out
    # takes the full budget. Anything under this fraction is the former.
    my $UNWATCHED = 0.9;

    # Write the framed read's result back into the caller's scalar (a reference to its
    # @_ slot), mimicking the builtin: undef (error) and 0 (EOF) leave the caller's
    # buffer alone; otherwise bytes before OFFSET are preserved and the read data is
    # placed at OFFSET.
    sub _store ( $slot, $off, $rc, $buf ) {
        return undef unless defined $rc;
        return 0 if 0 == $rc;
        $$slot = ( $off ? substr( $$slot // '', 0, $off ) : q{} ) . $buf;
        return $rc;
    }

    # Put a handle into non-blocking mode, answering the mode it was in, or undef when the platform will not.
    sub _try_nonblocking ($fh) {

        # `blocking` with no argument reports the current mode, and undef is its answer for a handle it cannot
        # interrogate: an already-closed glob, a dirhandle, a driver-supplied handle - and on Win32, a socket.
        # Winsock's FIONBIO can *set* a socket's mode but has no way to report one, so there the save half of a
        # save/restore does not exist. Nothing is lost by asking rather than assuming a platform: on the one
        # platform that cannot answer, the answer this read needs is already "no mode change", because sysread
        # hands back a short count on its own (see _read_nonblocking).
        my $was = IO::Handle::blocking($fh);
        return undef unless defined $was;

        # The setter answers with the mode it *replaced*, and -1 when it could not do the job at all. -1 is true, so
        # the return cannot be read as a success flag the way an undef could be; comparing against -1 is what tells
        # the two apart.
        my $replaced = IO::Handle::blocking( $fh, 0 );
        return defined $replaced && $replaced >= 0 ? $was : undef;
    }

    # Put a handle back the way the caller had it. The caller's own mode is what the handle looks like to every other
    # bit of code that touches it, including code compiled *before* installation, which still gets a raw blocking read
    # from this same handle. Restoring is what keeps transparent unblocking transparent.
    sub _restore_blocking ( $fh, $was ) {
        IO::Handle::blocking( $fh, $was ? 1 : 0 );
        return;
    }

    # Perform one read on a handle that is already known to be readable, WITHOUT letting a
    # short read park the OS thread.
    #
    # This is the whole point of the exercise. Perl's read() builtin does not return when *one* byte is available,
    # it keeps going until it has the *requested count* - so "await_read says ready, now read" froze the entire run
    # the moment a caller asked for more bytes than the peer had sent. Every fiber stalled, and because the fiber
    # was inside a syscall rather than parked in the scheduler, no deadline or token could rescue it either.
    #
    # So the handle is put into non-blocking mode for the duration of the read and put back afterwards, and the read
    # itself is done with the builtin that stops at whatever arrived.
    #
    # The mode is read and set through IO::Handle->blocking rather than through fcntl, and that is the whole
    # portability story. Fcntl's constant table has no F_GETFL or F_SETFL on Win32 at all, and naming one there does
    # not fail at compile time - it compiles as a call to a sub that does not exist and croaks at *runtime*, with
    # "Your vendor has not defined Fcntl macro F_GETFL" - so a POSIX-only fcntl call compiles silently on every
    # platform and then explodes exactly where it matters. IO::Handle already does the platform's own dispatch: fcntl
    # where that exists, Winsock's FIONBIO where it does not. FIONBIO is the same request number the hand-rolled
    # mode-flip carries, reached through a module that already knows it, and it comes back with an answer a caller
    # can act on instead of an exception.
    #
    # Only the *buffered* builtin needs the mode changed, and only where there is a mode to change. sysread stops at
    # a short count on every platform, on a blocking handle included: Winsock's recv - which is what a sysread on a
    # socket calls - hands back whatever has arrived rather than waiting for the caller's count. read's buffered
    # layer does loop internally until it has the full count, and it honours a non-blocking descriptor by stopping,
    # but only where one can be set. So the buffered read is used when the flip took and sysread otherwise, on either
    # side of that decision; the two agree on the count they return and differ only in whether perl's per-handle
    # buffer is in the path, which is invisible to a caller that does not mix buffered and unbuffered reads on one
    # handle (already undefined behaviour in perl).
    sub _read_nonblocking ( $fh, $len, $is_sys ) {
        no warnings 'io';
        my $was = $is_sys ? undef : _try_nonblocking($fh);
        my $buf = q{};
        my $rc  = defined $was ? CORE::read( $fh, $buf, $len, 0 ) : CORE::sysread( $fh, $buf, $len, 0 );
        _restore_blocking( $fh, $was ) if defined $was;
        return ( $rc, $buf );
    }

    sub install ( $class = () ) {
        return 1 if $INSTALLED;
        {
            no strict 'refs';
            no warnings 'redefine';

            # The three closures are built here as named lexicals and their coderefs are kept in @SAVED, so disable()
            # can withdraw the fabricated pad depth from the CV itself instead of looking the override back up with
            # *{ 'CORE::GLOBAL::read' }{CODE} -- a name lookup into a glob slot is a fragile thing to depend on when
            # holding the coderef costs nothing. (That lookup was not what was wrong on Win32 either: it returns a
            # proper CODE ref there, measured. The actual cause of the old croak was the signature of the C entry
            # point the override calls; see the note on para_release_cv_depth().) What disable() actually restores is
            # snapshotted just before the assignments below, so the coderef's own home glob is never the saved state.
            #
            # sleep [;$] maps to await_sleep. Fractional seconds are honored as
            # milliseconds (CORE::sleep truncates them away) and are impossible to
            # signal-interrupt inside a fiber, so the return value is the requested
            # duration. The $_ default is reproduced by hand: a CORE::GLOBAL override
            # does not get the builtin's implicit argument.
            my $sleep_override = sub : prototype(;$) {
                my $secs = @_ ? $_[0] : $_;
                $secs = 0 if !defined $secs || $secs < 0;
                return $secs              if 0 == $secs;
                return CORE::sleep($secs) if Acme::Parataxis->current_fid < 0;
                Acme::Parataxis->await_sleep( $secs * 1000 );
                return $secs;
            };

            # read/sysread frame a single CORE:: read on await_read readiness. A blocking
            # handle that select() marks readable hands over whatever is already buffered
            # (at least one byte, or 0 at EOF) without parking the OS thread, so one
            # readiness probe then one blocking read is cooperative. If the read races
            # EAGAIN/EWOULDBLOCK anyway, the loop re-waits; a read with no data cycles
            # the 5s await_read default forever, matching a blocking read.
            #
            # Note: the compiler passes the builtin's second argument BY VALUE to a
            # CORE::GLOBAL override (an lvalue like read()/sysread() accept is not
            # aliased), so the overrides are deliberately left WITHOUT a prototype and
            # read into a private $buf, then write the result back through _store. That
            # also keeps the `read $fh, $buf, 8` (no-parens) form working.
            my $read_override = sub {
                my $off = defined $_[3] ? $_[3] : 0;
                if ( 'Acme::Parataxis'->current_fid < 0 ) {
                    my $buf = '';
                    my $rc  = CORE::read( $_[0], $buf, $_[2], 0 );
                    return _store( \$_[1], $off, $rc, $buf );
                }
                while (1) {
                    my $t0    = Time::HiRes::time();
                    my $ready = Acme::Parataxis->await_read( $_[0], $PROBE_MS );
                    if ( $ready < 0 ) {

                        # A probe that gave up *short of its budget* means this platform cannot watch this handle
                        # at all - Win32's select() takes sockets only, so a pipe or a regular file answers -1
                        # immediately - rather than that a watchable handle merely had nothing to say. Read those
                        # directly, because there is nothing else left to try: a handle that cannot be watched
                        # cannot be parked on either, so a read of it is the only thing that can make progress, and
                        # refusing would mean such a handle never reads at all.
                        #
                        # The cost of that is real and is why it is reached only here: a read of a handle with
                        # nothing buffered yet parks the OS thread, and on Win32 a pipe is in exactly that state
                        # whenever a writer has not run yet - and the writer is usually a fiber, which cannot run
                        # because the thread that would run it is the one now inside the read. There is no fixing
                        # that from perl without a native overlapped-I/O wait, so a fiber that needs to *wait* on a
                        # non-socket handle on Win32 has to be driven from a socket or a driver instead.
                        #
                        # The test is re-armed every round rather than spent once, so one slow round does not cost
                        # the fallback permanently and leave the loop spinning a 5s probe at a time forever, and it
                        # is measured on a high-resolution clock so a probe that merely crosses a clock second is
                        # still recognised as short. A round that really did burn the whole budget is a genuine
                        # timeout, and raw-blocking on it would stall the process instead.
                        if ( Time::HiRes::time() - $t0 < $PROBE_MS / 1000 * $UNWATCHED ) {
                            my ( $rc, $buf ) = _read_nonblocking( $_[0], $_[2], 0 );
                            return _store( \$_[1], $off, $rc, $buf );
                        }
                        next;
                    }
                    my ( $rc, $buf ) = _read_nonblocking( $_[0], $_[2], 0 );
                    return _store( \$_[1], $off, $rc, $buf ) if defined $rc;
                    return undef unless $!{EAGAIN} || $!{EWOULDBLOCK};
                }
            };
            my $sysread_override = sub {
                my $off = defined $_[3] ? $_[3] : 0;
                if ( 'Acme::Parataxis'->current_fid < 0 ) {
                    my $buf = '';
                    my $rc  = CORE::sysread( $_[0], $buf, $_[2], 0 );
                    return _store( \$_[1], $off, $rc, $buf );
                }
                while (1) {
                    my $t0    = Time::HiRes::time();
                    my $ready = Acme::Parataxis->await_read( $_[0], $PROBE_MS );
                    if ( $ready < 0 ) {

                        # See the read override: a probe that gave up short of its budget is a handle this platform
                        # cannot watch, so read it raw rather than spin.
                        if ( Time::HiRes::time() - $t0 < $PROBE_MS / 1000 * $UNWATCHED ) {
                            my ( $rc, $buf ) = _read_nonblocking( $_[0], $_[2], 1 );
                            return _store( \$_[1], $off, $rc, $buf );
                        }
                        next;
                    }
                    my ( $rc, $buf ) = _read_nonblocking( $_[0], $_[2], 1 );
                    return _store( \$_[1], $off, $rc, $buf ) if defined $rc;
                    return undef unless $!{EAGAIN} || $!{EWOULDBLOCK};
                }
            };

            # Snapshot what each glob already holds *before* the assignments below rewrite it: disable() has to hand
            # the prior state back, and the glob itself cannot be the snapshot. \*{'CORE::GLOBAL::read'} taken here is
            # a live reference to the very glob this block then overwrites, so a disable that "restores" it is a
            # self-assignment -- a no-op that leaves the override in the glob once @SAVED and $INSTALLED are cleared.
            # The sole witness is the CODE slot: an installed override is a CODE slot on the CORE::GLOBAL::%s glob, and
            # a builtin occupies no slot at all, so undef *is* the builtin's identity and restoring is "empty the slot".
            my $sleep_prior   = *{'CORE::GLOBAL::sleep'}{CODE};
            my $read_prior    = *{'CORE::GLOBAL::read'}{CODE};
            my $sysread_prior = *{'CORE::GLOBAL::sysread'}{CODE};
            push @SAVED, [ sleep   => $sleep_prior,   $sleep_override ];
            push @SAVED, [ read    => $read_prior,    $read_override ];
            push @SAVED, [ sysread => $sysread_prior, $sysread_override ];
            *{'CORE::GLOBAL::sleep'}   = $sleep_override;
            *{'CORE::GLOBAL::read'}    = $read_override;
            *{'CORE::GLOBAL::sysread'} = $sysread_override;
        }
        $INSTALLED = 1;
        return 1;
    }

    sub disable ( $class = () ) {
        return 1 unless $INSTALLED;
        {
            no strict 'refs';
            no warnings 'redefine';

            # Hand back the pad bookkeeping for each override before the glob is touched. Fiber swaps fabricate a
            # CvDEPTH for a CV some fiber is parked inside, so that the next call lands above the parked pad -- but
            # nothing withdraws that value once the parked frame is gone, and the CV then looks permanently active to
            # perl. Overwriting such a CV finalises it (a hard "Can't undef active subroutine" pointing at the
            # *replaced* sub's own definition site, which is nowhere near the cause), so the count is withdrawn while
            # nothing else is happening to the CV. $entry->[2] is the coderef install() created; see the note there
            # for why it is held directly rather than re-looked-up, and why that was not the Win32 croak's cause.
            #
            # The restore itself is driven by the snapshot taken before install() overwrote each glob. A prior
            # override (someone else's, present before install) is handed back as the CODE slot it was; otherwise the
            # slot is emptied, which is the one way to tell perl the builtin is in effect again. The glob reference the
            # old code stored was a live alias of the glob install() was about to rewrite, so restoring it was a
            # self-assignment that uninstalled nothing.
            for my $entry (@SAVED) {
                my ( $name, $prior, $cv ) = @$entry;
                Acme::Parataxis::para_release_cv_depth($cv) if $cv;
                my $glob = 'CORE::GLOBAL::' . $name;
                if ( defined $prior && ref($prior) eq 'CODE' ) {
                    *{$glob} = $prior;    # hand the override that predated install() back
                }
                else {
                    undef *{$glob};       # builtin: no CODE slot is how perl knows the builtin is in effect
                }
            }
        }
        @SAVED     = ();
        $INSTALLED = 0;
        return 1;
    }
    sub installed ( $class = () ) { !!$INSTALLED }
};
#
1;
