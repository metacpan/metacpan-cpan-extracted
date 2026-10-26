use v5.40;
use blib;
use Test2::V1 -ipP;
use Time::HiRes      qw[time];
use File::Temp       ();
use IO::Handle       ();
use IO::Socket::INET ();
use Acme::Parataxis  qw[async fiber await_sleep with_timeout];

# Transparent unblocking is opt-in, per-process, compile-time. The overrides affect only code compiled AFTER
# enable_transparent_unblocking ran, so they are installed here in BEGIN, before the test bodies below are compiled.
# Everything at the top level (current_fid < 0) must delegate to the raw CORE:: builtins, and every call from inside a
# scheduled fiber frames on the scheduler's await_sleep/await_read so no OS thread is parked. Nothing is monkey-patched
# on other threads: a fresh interpreter starts with unmodified builtins.
BEGIN { Acme::Parataxis->enable_transparent_unblocking }
$|++;
#
sub socket_pair {
    my $server = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1 ) or die "listen: $!";
    my $client = IO::Socket::INET->new( PeerAddr  => '127.0.0.1:' . $server->sockport )                         or die "connect: $!";
    my $conn   = $server->accept or die "accept: $!";
    return ( $client, $conn );
}
#
# Whether select() will even take this handle. A zero timeout means "report what is ready now", so the answer costs
# nothing either way: 0 (or 1) means the handle was accepted, -1 means select() rejected the descriptor. That
# rejection is the whole reason a handle is unwatchable - Win32's select() takes sockets and nothing else - so it is
# also the honest way to ask whether a fiber could ever be parked on something, rather than naming an OS.
sub can_watch {
    my $in = q{};
    vec( $in, fileno( $_[0] ), 1 ) = 1;
    my $out = q{};
    my $n   = select( $in, $out, undef, 0 );
    return defined $n && $n >= 0;
}
#
subtest 'opt-in install is explicit and reports' => sub {
    is Acme::Parataxis->enable_transparent_unblocking(),  1, 'installing reports success';
    is Acme::Parataxis->enable_transparent_unblocking(),  1, 'second install is idempotent, not an error';
    is Acme::Parataxis->transparent_unblocking(),         1, 'transparent_unblocking() reflects the install';
    is Acme::Parataxis->current_fid,                     -1, 'top level is outside the scheduler (fid -1)';
};
subtest 'top-level sleep keeps raw CORE::sleep semantics' => sub {
    my $t0 = time;
    my $rc = sleep 0.05;
    my $ms = ( time - $t0 ) * 1000;
    ok $rc == int $rc, 'fractional seconds truncate to whole seconds, exactly like CORE::sleep';
    ok $ms < 5000,     "it returned promptly ($ms ms), never parking an OS thread";
};
subtest 'sleep inside a fiber is cooperative and yields' => sub {
    my ( @slow, $prog );
    async {
        my $t0    = time;
        my $slow  = fiber { push @slow, [ sleep(0.05), time - $t0 ] };
        my $ticks = fiber { await_sleep(1); my $p = 0; $prog += ++$p for 1 .. 40; 1 };
        $slow->await;
        $ticks->await;
    };
    ok $slow[0][0] > 0.04 && $slow[0][0] < 0.5, 'the sleep returned the requested seconds, not a truncated zero';
    ok $slow[0][1] >= 0.045,                    'the fiber actually waited ~50ms';
    ok $prog > 0,                               'a sibling fiber made progress while the sleeper was parked';
};
subtest 'the $_ default and fractional precision reach the scheduler' => sub {
    my ( $rc, $el );
    $_ = 0.04;
    async {
        my $t0 = time;
        $rc = sleep;        # implicit $_
        $el = time - $t0;
    };
    ok $rc > 0.03 && $rc < 0.5, 'sleep() with no argument used $_ (returned the requested duration)';
    ok $el >= 0.03,             "it actually waited ($el s)";
};
subtest 'top-level read/sysread still fill the caller buffer' => sub {
    for my $builtin (qw[read sysread]) {
        my ( $a, $b ) = socket_pair();
        syswrite $a, $builtin eq 'read' ? 'hihi' : 'yo!';
        my ( $buf, $rc );
        if ( $builtin eq 'read' ) { $rc = read( $b, $buf, 4 ) }
        else                      { $rc = sysread( $b, $buf, 3 ) }
        is $rc,  4, "$builtin at the top level returned the byte count" if $builtin eq 'read';
        is $rc,  3, "$builtin at the top level returned the byte count" if $builtin eq 'sysread';
        is $buf, $builtin eq 'read' ? 'hihi' : 'yo!', "$builtin at the top level filled the caller buffer";
    }
};
subtest 'read/sysread inside a fiber frame until the peer writes' => sub {
    for my $builtin (qw[read sysread]) {
        my ( $a, $b ) = socket_pair();
        my ( $buf, $rc );
        my $t0 = time;
        async {
            my $reader = fiber {
                if ( $builtin eq 'read' ) { $rc = read( $a, $buf, 7 ) }
                else                      { $rc = sysread( $a, $buf, 7 ) }
            };
            my $writer = fiber { await_sleep(30); syswrite $b, 'framed!' };
            $reader->await;
            $writer->await;
        };
        my $ms = ( time - $t0 ) * 1000;
        is $rc,  7,         "$builtin framed the payload written after the read parked";
        is $buf, 'framed!', "$builtin wrote the result back into the caller buffer";
        ok $ms < 4000, "the $builtin returned promptly ($ms ms) once the peer wrote";
    }
};
subtest 'a read asked for more than the peer sends returns the short count' => sub {

    # Every socket case above asks for exactly the number of bytes the peer sends, which is the one shape a blocking
    # read cannot get wrong. Ask for one more than arrives and the old override froze the entire run: await_read only
    # promises that *something* is readable, but a raw read on a blocking stream handle waits for the whole requested
    # count, so the fiber sat in a syscall where no deadline, no token and no sibling could reach it.
    for my $builtin (qw[read sysread]) {
        my ( $a, $b ) = socket_pair();
        syswrite $b, 'hello';    # five bytes down the wire to $a, then silence
        my ( $buf, $rc, $ticked );
        my $t0 = time;
        async {
            # The deadline below does NOT rescue this one if the override regresses: a fiber wedged in the read
            # syscall cannot be interrupted, because the timer fiber that would raise the deadline never gets
            # scheduled. It is here to catch a *spin* regression, which a deadline can stop. A return to plain
            # blocking reads stalls the run outright, so that failure mode is a stall to be read, not a red test.
            with_timeout(
                5000,
                sub {
                    my $ticks = fiber { await_sleep(30); $ticked = 1; 1 };
                    if ( $builtin eq 'read' ) { $rc = read( $a, $buf, 10 ) }
                    else                      { $rc = sysread( $a, $buf, 10 ) }
                    $ticks->await;
                }
            );
        };
        my $ms = ( time - $t0 ) * 1000;
        is $rc,  5,       "$builtin asked for 10, got 5, and returned the short count instead of waiting";
        is $buf, 'hello', "$builtin filled the caller buffer with the bytes that had arrived";
        ok $ms < 2000, "the $builtin returned promptly ($ms ms) instead of parking the OS thread";
        ok $ticked,    "a sibling fiber ran during the $builtin, so the rest of the run kept going";
    }
};
subtest 'the caller handle is handed back in the mode it arrived in' => sub {

    # The override makes the handle non-blocking only for the duration of its own read, then puts the mode back.
    # Anything else would break the gevent-style contract in reverse: code compiled *before* installation still gets a
    # raw blocking read from that same handle, and would start failing with EAGAIN if we left it flipped.
    #
    # Asked through IO::Handle->blocking, which is the interface the override itself uses and the only portable one -
    # Fcntl has no F_GETFL or F_SETFL on Win32 at all. It is not an interface that works *everywhere* either: Winsock's
    # FIONBIO can set a socket's mode but has no way to report one, so the getter answers undef there. The capability
    # is probed rather than assumed, so a platform that cannot answer is a skip and not a false pass.
    my ( $a, $b ) = socket_pair();
    plan skip_all => 'this platform cannot report a handle mode through IO::Handle' unless defined IO::Handle::blocking($a);
    for my $want ( 1, 0 ) {    # 1 = the socket default (blocking), 0 = the caller set non-blocking itself
        IO::Handle::blocking( $a, $want );
        my $before = IO::Handle::blocking($a) ? 1 : 0;
        syswrite $b, 'ok';
        my ( $buf, $rc );
        async { $rc = read( $a, $buf, 2 ) };
        my $after = IO::Handle::blocking($a) ? 1                    : 0;
        my $was   = $before                  ? 'non-blocking'       : 'blocking';
        my $now   = $after                   ? 'still non-blocking' : 'still blocking';
        is $rc,    2,       "an exact read on a handle the caller left $was worked";
        is $after, $before, "...and the handle is $now afterwards";
    }
};
subtest 'a pipe parks the fiber instead of freezing the thread' => sub {

    # Only a platform whose select() accepts a pipe can park here, and that is a question about the platform rather
    # than about the OS by name, so it is asked: select() is the mechanism the worker itself uses, and it answers
    # immediately either way. Win32's takes sockets only and reports ENOTSOCK for a pipe, which makes a pipe there
    # unwatchable - nothing for await_read to wait on, so the override's only remaining move is to read it, and a
    # read of a pipe with no writer yet parks the OS thread until the writer runs. The writer is usually a fiber, and
    # it cannot run, because the thread that would run it is the one now inside the read. That is a platform limit
    # rather than something this module can paper over; the regular-file subtest below still covers the unwatchable
    # fallback for the case it actually exists for, where the data is already there.
    pipe( my $r, my $w ) or die "pipe: $!";
    plan skip_all => 'select() cannot watch a pipe on this platform, so a fiber cannot wait on one' unless can_watch($r);
    my ( $buf, $rc, $ticked );
    my $t0 = time;
    async {
        with_timeout(
            5000,
            sub {
                my $ticks = fiber { await_sleep(30);  $ticked = 1; 1 };
                my $late  = fiber { await_sleep(150); syswrite $w, 'piped' };
                $rc = read( $r, $buf, 5 );
                $late->await;
                $ticks->await;
            }
        );
    };
    my $ms = ( time - $t0 ) * 1000;
    is $rc,  5,       'the read on a pipe returned the byte count once the writer got there';
    is $buf, 'piped', '...and filled the caller buffer';
    ok $ms >= 140, "the read waited for the late writer ($ms ms) rather than spinning or returning early";
    ok $ms < 3000, "...and returned promptly once the data arrived ($ms ms)";
    ok $ticked,    'a sibling fiber ran while the pipe read was parked';
};
subtest 'a regular file read inside a fiber falls back to the raw builtin' => sub {
    my $dir  = File::Temp->newdir( CLEANUP => 0 );
    my $path = File::Spec->catfile( $dir->dirname, 'x.txt' );
    open my $wr, '>', $path or die "write $path: $!";
    print $wr 'file read works';    # length 15
    close $wr;
    for my $builtin (qw[read sysread]) {
        my ( $buf, $rc );
        open my $fh, '<', $path or die "open $path: $!";
        async {
            with_timeout(
                15000,
                sub {
                    # Many reads, not one. The override times its readiness probe against the wall clock to tell
                    # "select() cannot watch this handle" (fall back to a raw read) from "a real wait timed out"
                    # (keep waiting), and a probe landing across a clock-second boundary used to be misread as the
                    # latter, after which the read spun until the deadline below killed it. A single read misses
                    # that most of the time, so it took a loaded machine and a full test run to notice; 150 reads
                    # inside one deadline hit it reliably. Rewind each time, since 15 bytes then hits EOF.
                    for ( 1 .. 150 ) {
                        seek( $fh, 0, 0 );
                        if ( $builtin eq 'read' ) { $rc = read( $fh, $buf, 15 ) }
                        else                      { $rc = sysread( $fh, $buf, 15 ) }
                    }
                }
            );
        };
        is $rc,  15,                "$builtin on a regular file inside a fiber returned the byte count, every time";
        is $buf, 'file read works', "$builtin on a regular file read the content (raw fallback, no spin)";
        close $fh;
    }
};
subtest 'more than one fiber can be inside a framed read at the same time' => sub {

    # A CORE::GLOBAL override is a single CV, and two fibers inside one at the same call depth share its @_: the
    # second to enter replaces the first one's slots. A framed read parks on await_read, so with its arguments
    # still being read out of @_ *after* that park, the fiber that parked first woke up to find its handle undef -
    # "Can't use an undefined value as a symbol reference" out of sysread, "...as filehandle reference" out of read,
    # both on a handle that had been perfectly good a moment earlier. One fiber at a time cannot see any of that,
    # and two fibers reading at once is the entire reason to install transparent unblocking in the first place.
    #
    # So every fiber here reads a *different* handle from the one it writes, which means every read genuinely parks
    # until a sibling fiber's write lands - the sibling can run precisely because the reader parked instead of
    # parking the OS thread - and all of them are inside the override together. The payloads are per-fiber and each
    # buffer is checked against the neighbour's, so a handle that comes back as the wrong one is caught even in the
    # cases where it comes back defined rather than undef.
    my $N    = 8;
    my $WIDE = 40;
    for my $builtin (qw[read sysread]) {
        my @pairs = map { [ socket_pair() ] } 1 .. $N;
        my ( @rc, @buf );
        async {
            with_timeout(
                30000,
                sub {
                    my @k;
                    for my $i ( 0 .. $N - 1 ) {
                        push @k, fiber {
                            my $j    = ( $i + 1 ) % $N;
                            my $mine = sprintf 'fiber-%02d-%s', $i, 'x' x $WIDE;
                            my $late = fiber { await_sleep(10); syswrite $pairs[$i][1], $mine; 1 };
                            my $buf  = q{};
                            my $rc   = $builtin eq 'read' ? read( $pairs[$j][0], $buf, length $mine ) : sysread( $pairs[$j][0], $buf, length $mine );
                            $late->await;
                            return [ $rc, $buf ];
                        };
                    }
                    for my $i ( 0 .. $N - 1 ) {
                        ( $rc[$i], $buf[$i] ) = @{ $k[$i]->await };
                    }
                }
            );
        };
        my @expect = map { sprintf 'fiber-%02d-%s', ( $_ + 1 ) % $N, 'x' x $WIDE } 0 .. $N - 1;
        is join( q{,},  @rc ),  join( q{,}, ( length $expect[0] ) x $N ), "$builtin: all $N concurrent reads returned the byte count";
        is join( q{\0}, @buf ), join( q{\0}, @expect ),                   "$builtin: every concurrent read filled the buffer with the right payload";
    }
};
subtest 'a fiber re-entering a framed read while a sibling is still parked keeps its own buffer' => sub {

    # The subtest above has every fiber read exactly once. This covers the other interleaving: fiber 0 finishes its
    # first read and calls the override *again* while fibers 1..3 are still parked inside theirs, so the shared CV
    # holds a live frame above one that has just parked, and the scheduler's landing-pad cleanup has to leave every
    # occupied pad alone. Tidying a sibling's live pad takes its @_ away mid-call, and what that costs depends on when
    # the override reads its arguments. Compat's reads them out of @_ after the park, so this dies with "Can't use an
    # undefined value as a filehandle reference"; an override that captures the handle first and parks afterwards fills
    # the caller's buffer correctly and then finds it emptied, because $_[1] is an alias for that buffer - a silent
    # loss rather than a croak. One fault, two faces; the assertions are on the outcome, not on which one arrives.
    #
    # The writers are staggered so fiber 0 is first to wake, and the assertions are on outcomes rather than on the
    # interleaving, so a schedule that fails to reproduce it still passes; it simply checks less.
    my $N     = 4;
    my @pairs = map { [ socket_pair() ] } 1 .. $N;
    my ( @rc, @buf );
    async {
        with_timeout(
            30000,
            sub {
                my @k;
                for my $i ( 0 .. $N - 1 ) {
                    push @k, fiber {
                        my @got;
                        for my $n ( 0, 1 ) {
                            last if $n == 1 && $i != 0;    # only fiber 0 reads twice
                            my $tag  = sprintf 'fiber-%02d-pass%d-%s', $i, $n, 'y' x 8;
                            my $ms   = 10 + 5 * ( $n == 0 ? $i : $N );
                            my $late = fiber { await_sleep($ms); syswrite $pairs[$i][1], $tag; 1 };
                            my $b    = q{};
                            my $rc   = read( $pairs[$i][0], $b, length $tag );
                            $late->await;
                            push @got, [ $rc, $b ];
                        }
                        return \@got;
                    };
                }
                my @all;
                for my $i ( 0 .. $N - 1 ) { push @all, @{ $k[$i]->await } }
                @rc  = map { $_->[0] } @all;
                @buf = map { $_->[1] } @all;
            }
        );
    };
    my ( @erc, @ebuf );
    for my $i ( 0 .. $N - 1 ) {
        for my $n ( 0, 1 ) {
            next if $n == 1 && $i != 0;
            my $tag = sprintf 'fiber-%02d-pass%d-%s', $i, $n, 'y' x 8;
            push @erc,  length $tag;
            push @ebuf, $tag;
        }
    }
    is join( q{,},  @rc ),  join( q{,},  @erc ),  'every read, the re-entering one included, returned the byte count';
    is join( q{\0}, @buf ), join( q{\0}, @ebuf ), '...and each kept its own payload, so no parked sibling buffer was emptied';
};
subtest 'disable restores the raw globals for freshly compiled code' => sub {
    is Acme::Parataxis->disable_transparent_unblocking(), 1, 'disabling reports success';
    is Acme::Parataxis->transparent_unblocking(),         0, 'no longer installed';
    my $first = eval 'package X1; use Time::HiRes qw[time]; my $t0 = time; my $rc = sleep(0.05); [ $rc, (time - $t0) * 1000 ]';
    is ref $first,  'ARRAY',            'freshly compiled sleep(0.05) ran';
    is $first->[0], int( $first->[0] ), '...and returned the truncated-to-integer CORE::sleep result, not the requested duration';
    ok $first->[1] < 5000, sprintf '...returned via the raw builtin (%f ms), not the scheduler', $first->[1];

    # A surviving CORE::GLOBAL override delegates to the raw builtin at the top level, so behaviorally it is
    # indistinguishable from being truly uninstalled -- which is exactly how disable() used to fail without anyone
    # noticing (the restored \*{...} glob ref was a live alias of the glob install() rewrote, so disable was a
    # self-assignment). The deterministic witness is the glob itself: an installed override is a CODE slot on
    # CORE::GLOBAL::%s, and the builtin occupies no slot at all, so the override is gone exactly when the slot reads
    # empty again.
    no strict 'refs';
    ok !( defined *{"CORE::GLOBAL::$_"}{CODE} ), "CORE::GLOBAL::$_ is empty again after disable" for qw[sleep read sysread];
    is Acme::Parataxis->enable_transparent_unblocking(), 1, 're-enabling works';
    ok defined *{"CORE::GLOBAL::$_"}{CODE}, "re-enable restores the CORE::GLOBAL::$_ override" for qw[sleep read sysread];
    is Acme::Parataxis->transparent_unblocking(), 1, 'and is reported installed again';
};
#
done_testing();
