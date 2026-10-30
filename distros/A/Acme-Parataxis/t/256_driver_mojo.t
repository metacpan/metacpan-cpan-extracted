use v5.40;
use experimental qw[class];
use blib;
use Test2::V1 -ipP;
use Config           qw[%Config];
use IO::Socket::INET ();
use Socket           qw[MSG_PEEK MSG_DONTWAIT];
use Time::HiRes      qw[time];
use Acme::Parataxis  qw[async fiber await_sleep await_read await_write with_timeout];
no warnings qw[recursion];
#
plan skip_all => 'Mojo::IOLoop not installed' unless eval { require Mojo::IOLoop; 1 };

# A fresh connected loopback socket pair. The driver flips the fd being watched to non-blocking, so (as the pool
# path does) the waiter end is the $b we park on; the peer end stays a plain blocking socket we write from.
sub socket_pair {
    my $server = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1 ) or die "listen: $!";
    my $client = IO::Socket::INET->new( PeerAddr  => '127.0.0.1:' . $server->sockport )                         or die "connect: $!";
    my $conn   = $server->accept or die "accept: $!";
    return ( $client, $conn );
}

# $n connected loopback pairs off a single listener. Connect and accept are interleaved so the listen backlog is
# never asked to hold more than one pending connection, which keeps hundreds of pairs cheap to build.
sub socket_pairs ($n) {
    my $server = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 64, ReuseAddr => 1 ) or die "listen: $!";
    my ( @writers, @waiters );
    for ( 1 .. $n ) {
        my $client = IO::Socket::INET->new( PeerAddr => '127.0.0.1:' . $server->sockport ) or die "connect: $!";
        my $conn   = $server->accept                                                       or die "accept: $!";
        push @writers, $client;
        push @waiters, $conn;
    }
    return ( \@writers, \@waiters );
}

# How many pairs to actually ask for, given a target. Every pair holds two descriptors open for the whole subtest, and
# the soft RLIMIT_NOFILE is not the same on every platform this runs on: Haiku and the BSDs ship far below the Linux
# default, so a fixed 300 used to die partway through the build with EMFILE and take the whole leg red. Rather than
# ask each OS what its limit is, try the real thing - open the pairs, and halve on EMFILE/ENFILE until one size fits.
# The probe runs in this same process against this same soft limit, so the number it settles on is the number that
# will still be there when the subtest asks for it.
#
# RLIMIT_NOFILE is not the only ceiling, and on NetBSD it is not the binding one. The platform's FD_SETSIZE bounds
# the descriptor NUMBER rather than the count: 300 pairs open 600 descriptors and reach fd 605, comfortably past
# NetBSD's FD_SETSIZE of 256 and nowhere near Linux's 1024, and an fd_set that size cannot name a descriptor at all.
# Two descriptors per pair, plus a listener and the handful of handles already open, is the budget that leaves.
# Measured from C because perl cannot measure it - `getconf FD_SETSIZE` is not a valid symbol and answers 20, and
# Fcntl::FD_SETSIZE() dies at runtime - and on NetBSD that number is the whole difference between this leg passing
# and not.
sub pairs_that_fit ($want) {
    my $n   = $want;
    my $cap = int( ( Acme::Parataxis::fd_setsize() - 16 ) / 2 );
    $n = $cap if $n > $cap;
    while ( $n > 8 ) {
        my ($probe) = eval { socket_pairs($n) };
        return $n if $probe;
        die $@ unless $!{EMFILE} || $!{ENFILE};
        $n = int( $n / 2 );
    }
    return $n;
}
ok !Acme::Parataxis->loop,                             'no driver before any attach';
ok !Acme::Parataxis->attach_loop( Mojo::IOLoop->new ), 'attach_loop returns undef the first time';
my $drv = Acme::Parataxis->loop;
ok ref($drv) && $drv->isa('Acme::Parataxis::Driver'), 'current loop is a wrapped driver';
ok $drv->isa('Acme::Parataxis::Driver::Mojo'),        'it is the Mojo driver';
is Acme::Parataxis->attach_loop( Mojo::IOLoop->new ), $drv, 'reattaching returns the previous driver';

# Reattaching installs a *fresh* driver, so compare detach against the driver that is current right now rather than
# the $drv stashed before the reattach (a stashed one is stale for every driver, Mojo included).
my $current = Acme::Parataxis->loop;
is Acme::Parataxis->detach_loop(), $current, 'detach_loop returns the current driver';
ok !Acme::Parataxis->loop, 'no driver after detach';
like dies { Acme::Parataxis->attach_loop('garbage') }, qr[requires an event-loop object], 'attach_loop rejects a non object';
ok !dies { Acme::Parataxis->detach_loop() }, 'a detached handle has no effect';
subtest 'a parked driver read wakes when the peer writes' => sub {
    my ( $a, $b ) = socket_pair();
    Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
    my $e;
    my $t0 = time;
    Acme::Parataxis::run(
        sub {
            my $f = fiber { await_sleep(30); syswrite $a, 'ping' };
            $e .= 'rc=' . await_read( $b, 2000 );
            my $buf = '';
            sysread $b, $buf, 4;
            $e .= " buf=$buf";
        }
    );
    my $ms = ( time - $t0 ) * 1000;
    Acme::Parataxis->detach_loop;
    is $e, 'rc=1 buf=ping', 'the parked read returned 1 with the bytes available';
    ok $ms >= 20 && $ms < 1200, 'it woke on the write, not on its deadline (ms)';
};
subtest 'a short driver deadline returns -1 (resumed, not thrown)' => sub {
    my ( $a, $b ) = socket_pair();
    Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
    my $got;
    my $t0 = time;
    Acme::Parataxis::run( sub { $got = await_read( $b, 60 ) } );
    my $ms = ( time - $t0 ) * 1000;
    Acme::Parataxis->detach_loop;
    is $got, -1, 'own deadline returned -1 like the pool path';
    ok $ms >= 40 && $ms < 1100, 'the deadline really waited before firing (ms)';
};
subtest 'an enclosing with_timeout still interrupts a driver read' => sub {
    my ( $a, $b ) = socket_pair();
    Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
    my ( $err, $after );
    Acme::Parataxis::run(
        sub {
            $err = dies {
                with_timeout( 30, sub { await_read( $b, 2000 ) } );
            };
            $after = 'ran-on';
        }
    );
    Acme::Parataxis->detach_loop;
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'enclosing ::Timeout propagated';
    is $err->kind, 'timeout', 'kind is timeout';
    is $after,     'ran-on',  'the fiber continued after catching it';
};
subtest 'a driver sleep mixes with a concurrent pool job' => sub {
    Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
    my ( $pool, $ms );
    my $t0 = time;
    Acme::Parataxis::run(
        sub {
            my $pw = fiber { await_sleep(20); 'pool-writer' };
            await_sleep(40);
            $pool = $pw->await;
        }
    );
    $ms = ( time - $t0 ) * 1000;
    Acme::Parataxis->detach_loop;
    is $pool, 'pool-writer', 'the driver sleep ran the run while the pool fiber completed';
    ok $ms >= 30 && $ms < 600, 'the sleep actually slept ~40ms (ms)';
};

# event-loop acceptance: high-volume readiness on the loop, and proof that the worker pool does none of it.
# Count every pool submission. _submit_job is the only gate onto submit_c_job (await_sleep, await_core_id,
# await_read and await_write all route through it) and run() never submits on its own, so a zero count while a
# loop is attached means no worker thread was ever asked to provide readiness or a sleep.
my $submits         = 0;
my $orig_submit_job = \&Acme::Parataxis::_submit_job;
{
    no warnings 'redefine';
    *Acme::Parataxis::_submit_job = sub ( $type, $arg, $timeout ) { $submits++; $orig_submit_job->( $type, $arg, $timeout ) };
}

# Windows: stock Strawberry perl builds without d_poll, so Mojo::Reactor::Poll drives IO::Poll::_poll through its
# select fallback. The limit there is the descriptor NUMBER, not the watch count: winsock FD_SETSIZE truncates the
# fd_set at 64, so the reactor goes silent as soon as any watched fd reaches 64 (5 watches woke 5/5 at maxfd 13,
# 5 watches after 70 dummy fds woke 0/5), IO::Select never crashes but reports at most 64 ready handles, and the
# pure-Mojo stack crashes the interpreter above 128 pairs on perl 5.42.3. 24 pairs keep every fd under 64, which
# is enough to exercise the whole driver path on Windows; other platforms ask for the full 300, less whatever their
# own two ceilings cannot hold - see pairs_that_fit.
my $N = pairs_that_fit( $^O eq 'MSWin32' ? 24 : 300 );

# The cap is only as good as the number behind it, and a broken accessor would shrink this workload quietly rather
# than fail: 0 gives a negative cap, pairs_that_fit's halving loop never runs on a negative, and $N would just come
# back small with every assertion below still green. Ask for the number directly so that shows up as a failure.
ok Acme::Parataxis::fd_setsize() >= 64, 'the platform reports a usable FD_SETSIZE (' . Acme::Parataxis::fd_setsize() . ')';
ok $N >= 8,                             "the high-volume workload kept a workable $N pairs";

# A lost wakeup in the high-volume batch is intermittent and platform-shaped, so a bare count is close to useless
# when one does happen: it cannot say whether the stragglers were a contiguous tail or scattered singles, whether
# their descriptors clustered past a ceiling, or whether await_read hit its timeout (undef) or returned something
# else. Those three answers point at different bugs, so the failure diagnostic carries all of them along with the
# reactor actually in play. Only ever runs after the count assertion has already failed.
sub lost_diagnosis ( $got, $fd, $loop, $n, $ms, $snap, $arms_end, $awaiting ) {
    my @lost = grep { !( defined $got->[$_] && $got->[$_] == 1 ) } 0 .. $#$got;
    my @kept = grep { defined $got->[$_] && $got->[$_] == 1 } 0 .. $#$got;
    my @out  = ( 'lost ' . @lost . " of $n parked reads" );
    return join "\n", @out if !@lost;

    # A run of consecutive indices is one lost batch; scattered singles are a different failure.
    my @runs;
    for my $i (@lost) {
        if ( @runs && $runs[-1][1] == $i - 1 ) { $runs[-1][1] = $i }
        else                                   { push @runs, [ $i, $i ] }
    }
    push @out, 'lost as ' . scalar(@runs) . ' run(s) of index: ' . join( ', ', map { $_->[0] == $_->[1] ? $_->[0] : "$_->[0]-$_->[1]" } @runs );

    # What await_read returned, so a timeout can be told apart from a wrong or empty read.
    my %count;
    $count{ defined $got->[$_] ? $got->[$_] : 'undef (timed out)' }++ for @lost;
    push @out, 'await_read returned: ' . join( ', ', map {"$_ x $count{$_}"} sort keys %count );

    # Descriptor numbers decide between the two live theories: clustering past FD_SETSIZE or some other ceiling is a
    # bound, scattering evenly through the range is a race.
    push @out, 'lost fds: ' . fd_span( [ map { $fd->[$_] } @lost ] );
    push @out, 'kept fds: ' . fd_span( [ map { $fd->[$_] } @kept ] );

    # Where the lost descriptors sit inside the full range, stated as a plain fact: a lost set that is entirely in
    # the top half points at a bound, one scattered evenly through the range points at a race. The reader decides.
    my @lost_fd = sort { $a <=> $b } grep {defined} map { $fd->[$_] } @lost;
    my @all_fd  = sort { $a <=> $b } grep {defined} map { $fd->[$_] } 0 .. $#$got;
    my $mid     = $all_fd[ int( @all_fd / 2 ) ];
    push @out,
        sprintf( 'descriptors in play span %d..%d; every lost fd is %s the midpoint (%d)',
        $all_fd[0], $all_fd[-1], $lost_fd[0] > $mid ? 'above' : 'below', $mid )
        if @lost_fd && @all_fd > 1;

    # Which reactor was in play. The class alone is not enough to name the waiting syscall, and a previous version of
    # this line overclaimed: it walked KQueue/Epoll/Poll and printed "backend: Poll" on a macOS leg, but
    # Mojo::Reactor::Poll is the only class there and it fronts all of them, so that label was never evidence of
    # anything. The syscall is chosen inside core's IO::Poll::_poll, which exposes no accessor to ask, so say that
    # rather than invent one. MOJO_REACTOR overrides the whole choice, so report it when set.
    my $reactor = eval { $loop->reactor };
    push @out, 'reactor: ' . ( ref($reactor) || 'unknown (no reactor)' ) . ( $ENV{MOJO_REACTOR} ? " (MOJO_REACTOR=$ENV{MOJO_REACTOR})" : '' );
    push @out, 'the wait syscall is chosen inside IO::Poll::_poll and is not introspectable; ' . 'read it from the d_* row below';

    # The d_* row is therefore the real evidence, and FD_SETSIZE is only a bound on the select(2) fallback, so it
    # means something different per backend. Reporting the number alone invited reading a descriptor ceiling into a
    # kqueue run, which the two observed losses contradict. osname/archname and the key count lead the row because
    # an all-undef d_* line is ambiguous: it means "this perl configured no poll backend" only if %Config is actually
    # populated, and without the count there is no way to tell that from a broken read on the reporting machine.
    push @out,
        sprintf( 'perl %vd %s %s (%d Config keys)', $^V, $Config{osname} // 'unknown-os', $Config{archname} // 'unknown-arch', scalar keys %Config );
    push @out,
        sprintf(
        'FD_SETSIZE %d, d_poll %s, d_ppoll %s, d_epoll %s, d_kqueue %s',
        Acme::Parataxis::fd_setsize(),
        map { exists $Config{$_} ? ( defined $Config{$_} ? $Config{$_} : 'undef' ) : 'ABSENT' } qw[d_poll d_ppoll d_epoll d_kqueue]
        );

    # Total elapsed separates "the stragglers used the whole timeout" (the batch ran ~5000ms) from "they were lost
    # and the batch returned early", and a run duration near the 5000ms timeout means every lost read sat it out.
    push @out, sprintf( 'batch elapsed %.0fms (await_read timeout was 5000ms)', $ms );
    push @out, layer_census( \@lost, $fd, $snap, $arms_end, $awaiting );
    return join "\n", @out;
}

# The fork. Parataxis and the reactor are asked separately whether each lost descriptor is still being watched, and
# the kernel is asked independently whether it is readable, so the loss lands in exactly one layer. A bare "lost 66
# of 300" cannot do this: the count is the same whether the watch was never made, was made and dropped on the way
# to Mojo, or was live and the event never came back.
sub layer_census ( $lost, $fd, $snap, $arms_at_end, $awaiting ) {
    return 'no mid-batch census: the sampler did not run' if !$snap;
    my @out;

    # Keyed by descriptor, never by position in the batch. An earlier per-index bit string assumed one descriptor
    # produced exactly one bit, and a descriptor with no fileno broke that silently, so a batch index could name
    # the wrong descriptor and the whole classification was fiction. This form has no positions to get wrong.
    my %para   = map { $_ => 1 } grep {length} split /,/, ( $snap->{para}   // '' );
    my %mojo   = map { $_ => 1 } grep {length} split /,/, ( $snap->{mojo}   // '' );
    my %kernel = map { $_ => 1 } grep {length} split /,/, ( $snap->{kernel} // '' );
    my %peek   = map { $_ => 1 } grep {length} split /,/, ( $snap->{peek}   // '' );
    push @out,
        sprintf(
        'mid-batch census: %d waiters on %d distinct descriptors (%d without a fileno), ' .
            'driver->watch_count %d, Parataxis holding %d, the reactor holding %d, select() calling %d readable, ' .
            'recv(MSG_PEEK) finding %d',
        $snap->{n},        $snap->{distinct}, $snap->{skipped},    $snap->{watch_ct},
        scalar keys %para, scalar keys %mojo, scalar keys %kernel, scalar keys %peek
        );
    push @out, '  descriptors claimed by more than one waiter: ' . fd_span( [ split /,/, ( $snap->{dupes} // '' ) ] )
        if length( $snap->{dupes} // '' );
    my @disagree = grep { ( $kernel{$_} ? 1 : 0 ) != ( $peek{$_} ? 1 : 0 ) } keys %kernel, keys %peek;
    push @out,
        '  select() and recv(MSG_PEEK) disagree about ' .
        scalar(@disagree) .
        ' descriptors, so trust neither: the readable count above is not evidence'
        if @disagree;
    push @out,
        "  $awaiting of them were still reporting no data when the 500ms wait ran out, so the readable" .
        ' count above is a floor, not the whole picture'
        if $awaiting > 0;

    # Every lost read is classified on its own descriptor's three answers. Branching on whether a *total* came out
    # zero is worse than useless here, and has already been wrong in the field: a real failure had 2 of its 31 lost
    # descriptors watched, which is overwhelmingly "unwatched" but not zero, so every zero-test passed and the
    # verdict reported all clear and named the reactor. The 29 nobody was watching out of 31 were the finding.
    my ( $k_all, $unmapped, %how ) = ( 0, 0, () );
    for my $i (@$lost) {
        my $d = $fd->[$i];
        if ( !defined $d ) { $unmapped++; next }
        my ( $p, $m, $k ) = ( $para{$d} ? 1 : 0, $mojo{$d} ? 1 : 0, $kernel{$d} ? 1 : 0 );
        $k_all += $k;
        $how{ !$p &&
                !$m ? ( $k ? 'unwatched by both layers, kernel had data' : 'unwatched by both layers, kernel had nothing' ) : $p &&
                !$m ? 'watched by Parataxis, absent from the reactor'                                                       : !$p &&
                $m  ? 'in the reactor, absent from Parataxis' : !$k ? 'watched by both, kernel had nothing' : 'watched by both, kernel had data' }++;
    }
    push @out, sprintf( '  of the %d lost reads, %d were unmappable, and the kernel had data for %d:', scalar @$lost, $unmapped, $k_all );
    push @out, "  $_: $how{$_}" for sort keys %how;

    # Late or never is the one thing a snapshot cannot answer by itself, so say it from the two arming tallies
    # against the size of the batch. Phrased off the counts rather than off "the unwatched fibers", which would
    # claim there were unwatched reads in the cases where every read was watched and the fault is elsewhere.
    my $at_sample = defined $snap->{arm_n} ? $snap->{arm_n} : -1;
    my $at_end    = defined $arms_at_end   ? $arms_at_end   : -1;
    my $batch     = $snap->{n};
    push @out, sprintf( '  the driver was asked to arm %d watches by the sample and %d by the end of a %d-read batch', $at_sample, $at_end, $batch );

    # What those arming calls were keyed on. %watches is fileno => the handle being watched, so two registrations
    # that arrive with the same descriptor number collapse into a single slot and watch_count falls by exactly the
    # number of repeats. That makes "300 arms but 176 watches" arithmetic rather than mysterious, and it is
    # separable from a watch that was never made: a repeat here is a registration that happened, keyed to the wrong
    # descriptor; no repeat here means the missing slots were never created at all. Stated as the count it is, with
    # the repeats listed, because a bare shortfall has twice now been read as a ceiling.
    if ( defined $snap->{arm_distinct} ) {
        my @dupes = grep {length} split /,/, ( $snap->{arm_dupes} // '' );
        push @out,
            sprintf(
            '  those %d arming calls used %d distinct descriptors, collapsing %d watches into a ' . 'descriptor number claimed more than once: %s',
            $at_sample, $snap->{arm_distinct},
            $at_sample - $snap->{arm_distinct},
            @dupes ? fd_span( \@dupes ) : 'none, so no two registrations shared a descriptor'
            );
    }
    my $never = $batch - $at_end;
    push @out,
        $never > 0           ? sprintf( '  so %d of the %d reads were NEVER asked to arm a watch, even by the end of the batch', $never, $batch ) :
        $at_sample < $at_end ? '  so every read did arm, but some armed only after the sample: they were LATE' :
        '  so every read was armed by the sample and none armed after it';

    # The dominant class, with its reading spelled out. Every class is listed above, so this is a summary of what
    # is already on the record rather than the only thing on it.
    my %why = (
        'unwatched by both layers, kernel had nothing' =>
            'the descriptor was never watched and never became readable, so there was nothing to wake on',
        'unwatched by both layers, kernel had data' =>
            'the kernel had data and no layer was watching: the watch was never registered for these reads',
        'watched by Parataxis, absent from the reactor' =>
            'Parataxis armed its own table but the watch never reached the reactor, so the fault is in ' . 'Driver::Mojo::_watch',
        'in the reactor, absent from Parataxis' => 'the reactor held a watch Parataxis had not recorded, so the two tables disagree',
        'watched by both, kernel had nothing'   => 'watched by both layers but the descriptor was not readable, so the batch never wrote to it',
        'watched by both, kernel had data'      =>
            'the watch was live on both sides and the kernel had data, so the readiness event was lost above the ' . 'kernel, inside the reactor',
    );
    my ($top) = sort { $how{$b} <=> $how{$a} || $a cmp $b } keys %how;
    push @out, "reading of the loss: $why{$top}" if $top;
    return join "\n", @out;
}

# Min..max of a descriptor list, plus whether it is contiguous, which separates "one block" from "all over".
sub fd_span ($f) {
    return 'none' if !@$f;
    my @s = sort { $a <=> $b } @$f;
    my $n = scalar @s;
    return "$s[0] (1 value)" if $n == 1;
    for my $i ( 1 .. $#s ) {
        return sprintf( '%d..%d, %d values, not contiguous', $s[0], $s[-1], $n ) if $s[$i] != $s[ $i - 1 ] + 1;
    }
    return "$s[0]..$s[-1] ($n values, all consecutive)";
}

# attach_loop() hands back the driver it *replaced*, not the one it just built, so the live driver is not reachable
# from a test without help. Driver::wrap() is the single call that constructs it, so note what comes out of that.
# Test-side only: nothing under lib/ changes and the shim returns exactly what the original returned.
my $LIVE_DRIVER;

BEGIN {
    require Acme::Parataxis::Driver;
    no warnings 'redefine';
    my $orig_wrap = \&Acme::Parataxis::Driver::wrap;
    *Acme::Parataxis::Driver::wrap = sub { my $d = $orig_wrap->(@_); $LIVE_DRIVER = $d; return $d };
}

# Whether a watch was armed late or never armed at all is invisible from any count taken after the fact: by then
# the fiber has finished and unwatched its descriptor either way, and the census sees the same thing. So count the
# _watch calls as they happen and let the census compare that tally against its own snapshot. A count that is short
# at the sample and complete by the end means the fibers were late; a count that is still short at the end means
# they were never asked at all. Test-side only, the original is always called, and the tally is two scalars.
my ( $arm_n, $arm_fds );
{
    no warnings 'redefine';
    my $orig_watch = \&Acme::Parataxis::Driver::Mojo::_watch;
    *Acme::Parataxis::Driver::Mojo::_watch = sub ( $self, $fh, $dir, $cb ) {
        $arm_n++;
        $arm_fds .= ( fileno($fh) // '?' ) . ',';
        return $orig_watch->( $self, $fh, $dir, $cb );
    };
}

# Is the kernel willing to read this descriptor right now? The referee in the three-way comparison below: whatever
# Parataxis and the reactor agree about is only interesting next to what the kernel itself says.
sub fd_readable ($fh) {
    my $vec = '';
    vec( $vec, fileno($fh), 1 ) = 1;
    my $n = select( $vec, undef, undef, 0 );
    return $n > 0 ? 1 : 0;
}

# The same question asked a second way, because the whole census rests on fd_readable and select() is the one
# call here that behaves differently per platform -- a leg whose kernel reports nothing readable when 300 sockets
# were just written to is either a real and startling fact or this function lying. recv() with MSG_PEEK|MSG_DONTWAIT
# does not block and consumes nothing, so the two can be compared instead of one being believed.
#   1 data is waiting, 0 none is, -1 MSG_DONTWAIT is unavailable here so the question was not asked.
# The answer is read out of the buffer, not recv()'s return value: on perl 5.44.0 that returns '' after filling the
# buffer with five bytes, so a referee trusting it reports "no data" on a socket that is demonstrably holding one.
sub fd_peekable ($fh) {
    return -1 if !defined &Socket::MSG_DONTWAIT;
    my $scratch = '';
    recv( $fh, $scratch, 1, MSG_PEEK | MSG_DONTWAIT );
    return length($scratch) ? 1 : 0;
}

# What each layer believed it was holding, sampled at the instant every watch is armed and every byte written and
# before the scheduler has resumed anything. This has to be taken mid-batch: detach_loop() unwinds every watch and
# timer at the end of the subtest, so a count read after the run is zero on all three sides and cannot tell them
# apart. The three views localise a loss to exactly one layer:
#   Parataxis watches it, the reactor does not  -> Driver::Mojo::_watch armed its own table but never reached Mojo
#   neither holds it                            -> await_read never registered a watch at all
#   both hold it, the kernel calls it readable  -> the watch was live and the loss is above the kernel, in Mojo
# Wait until every waiter reports data, or the budget runs out, and return how many are still waiting. The census
# asks the kernel whether the byte is there, so the byte has to have arrived before the question means anything.
# Loopback delivery is not instantaneous: on this box a byte written to a loopback peer took about a millisecond to
# show up as readable, and a macOS leg's census saw none of 300 -- which reads as "the batch never wrote to it" when
# it only ever meant "the sample was taken before the data landed". This is a synchronous loop in the main fiber,
# so no parked fiber gets a chance to wake and eat its byte first, and the census still sees the batch as written.
sub wait_for_data ( $waiters, $budget_ms ) {
    my @fds = grep {defined} map {
        eval { fileno($_) }
    } @$waiters;
    my $deadline = time + $budget_ms / 1000;
    my $missing  = scalar @fds;
    while ( $missing > 0 ) {
        my $remain = $deadline - time;
        last if $remain <= 0;
        my $v = '';
        vec( $v, $_, 1 ) = 1 for @fds;
        my $ready = select( $v, undef, undef, $remain > 0.05 ? 0.05 : $remain ) || 0;
        $missing = scalar(@fds) - $ready;
    }
    return $missing;
}

sub armed_snapshot ( $loop, $waiters ) {
    my $driver  = $LIVE_DRIVER;
    my $reactor = eval { $loop->reactor };
    my $io      = ( $reactor && ref $reactor->{io} eq 'HASH' ) ? $reactor->{io} : {};

    # One comma-joined, sorted descriptor list per layer, reduced here at the sample. A per-index bit string was
    # tried first and was wrong: a descriptor with no fileno was skipped without appending, which shifts every
    # later bit by one and makes the batch index point at the wrong descriptor, silently. Keying by descriptor
    # assumes no positions at all, and a plain string crosses back out of the fiber intact.
    my ( @para, @mojo, @kernel, @peek );
    my ( %seen, %repeat, @dupe );
    my $skipped = 0;
    for my $fh (@$waiters) {
        my $fd = eval { fileno($fh) };
        if ( !defined $fd ) { $skipped++; next }

        # Both layers key their tables by descriptor, so a descriptor claimed by two waiters is one watch, not two.
        # That makes "300 reads" and "227 watches" arithmetically consistent without anything being lost at all, and
        # this whole diagnostic has been comparing watch counts against read counts without ever checking it.
        push @dupe,   $fd if $seen{$fd}++;
        push @para,   $fd if $driver && $driver->has_watch($fh);
        push @mojo,   $fd if exists $io->{$fd};
        push @kernel, $fd if fd_readable($fh);
        my $p = fd_peekable($fh);
        push @peek, $fd if $p;
    }
    return {
        para     => join( ',', sort { $a <=> $b } @para ),
        mojo     => join( ',', sort { $a <=> $b } @mojo ),
        kernel   => join( ',', sort { $a <=> $b } @kernel ),
        peek     => join( ',', sort { $a <=> $b } @peek ),
        n        => scalar @$waiters,
        distinct => scalar keys %seen,
        dupes    => join( ',', sort { $a <=> $b } @dupe ),
        skipped  => $skipped,
        arm_n    => $arm_n,

        # The descriptor each arming call actually passed in, distinct count and repeats. Without this the census
        # compares "300 arms" against "176 watches" and has no way to tell a collapsed key from a missing one: both
        # arithmetic routes land on the same two numbers, and the 176 figure has been sitting in the log looking like
        # a resource bound. _track_watch keys by fileno, so a number claimed twice collapses two registrations into
        # one and the count falls by exactly the number of repeats. This is the line that settles it.
        arm_distinct => scalar keys %{ { map { $_ => 1 } grep { $_ ne '?' } split /,/, ( $arm_fds // '' ) } },
        arm_dupes    => join( ',', sort { $a <=> $b } grep { $_ ne '?' } grep { $repeat{$_}++ > 0 } ( split /,/, ( $arm_fds // '' ) ) ),
        watch_ct     => ( $driver ? $driver->watch_count : -1 ),
        reactor      => ref($reactor) || 'none',
    };
}
subtest "high-volume: $N concurrent await_read wake on loopback" => sub {
    my ( $writers, $waiters ) = socket_pairs($N);
    my $loop = Mojo::IOLoop->new;
    Acme::Parataxis->attach_loop($loop);
    $submits = 0;
    $arm_n   = 0;    # this subtest's arming tally only, not the whole file's
    $arm_fds = '';
    my @got;
    my @fd;                # the descriptor each fiber actually parked on, captured before the batch runs
    my $snap;              # the three layers' views, sampled while the batch is still live
    my $arms_end;          # the same tally once the batch has finished, to tell "late" from "never"
    my $awaiting = -1;     # descriptors still reporting no data at the sample, i.e. the waiter's budget ran out
    my $t0       = time;
    Acme::Parataxis::run(
        sub {
            # Park every fiber on its own descriptor first; the writer only fires once all $N watches are armed, so
            # this exercises N descriptors parked at once rather than N reads that were ready from the start.
            my @fibers = map {
                my $i = $_;
                $fd[$i] = fileno( $waiters->[$i] );
                fiber { $got[$i] = await_read( $waiters->[$i], 30_000 ) }
            } 0 .. $N - 1;
            await_sleep(50);
            syswrite $writers->[$_], 'x' for 0 .. $N - 1;

            # Every byte is written and nothing has been resumed yet, so this is the last moment at which "who
            # thinks it is watching what" is a meaningful question. The data has to have landed first, or the
            # kernel is being asked about delivery latency rather than about the watch.
            $awaiting = wait_for_data( $waiters, 500 );
            $snap     = armed_snapshot( $loop, $waiters );
            $_->await for @fibers;
        }
    );
    my $ms              = ( time - $t0 ) * 1000;
    my $attached_submit = $submits;
    $arms_end = $arm_n;
    Acme::Parataxis->detach_loop;
    my $woke = grep { defined $_ && $_ == 1 } @got;
    is $woke, $N, "all $N parked reads woke with their byte" or diag lost_diagnosis( \@got, \@fd, $loop, $N, $ms, $snap, $arms_end, $awaiting );
    is $attached_submit, 0, "no worker-pool job was submitted for any of the $N reads";
    ok $ms < 15000, sprintf( 'the whole batch completed in %.0fms', $ms );
};
subtest 'the pool-submission counter is live, not vacuous' => sub {

    # Same workload shape with no loop attached. If the counter never increments here, the zero above would prove
    # nothing at all, so this is the control that keeps the assertion honest.
    my ( $writers, $waiters ) = socket_pairs(1);
    $submits = 0;
    my $got;
    Acme::Parataxis::run(
        sub {
            my $f = fiber { await_sleep(30); syswrite $writers->[0], 'ping' };
            $got = await_read( $waiters->[0], 2000 );
            $f->await;
        }
    );
    my $pool_submit = $submits;
    is $got, 1, 'the pool path completed the same workload';
    cmp_ok $pool_submit, '>=', 2, "the pool path submitted for both the read and the sleep ($pool_submit)";
    {
        no warnings 'redefine';
        *Acme::Parataxis::_submit_job = $orig_submit_job;
    }
};
#
done_testing;
