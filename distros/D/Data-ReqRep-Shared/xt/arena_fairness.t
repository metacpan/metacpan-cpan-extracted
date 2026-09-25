use strict;
use warnings;
use Test::More;
use POSIX ();
use File::Temp qw(tempdir);
use Time::HiRes qw(time sleep setitimer ITIMER_REAL);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $p = tempdir(CLEANUP => 1) . '/fair.shm';
my @geom = ($p, 1024, 1024, 16, 256);
my $srv = Data::ReqRep::Shared->new(@geom);
my $stop = time + 20;
my @kids;
for (1 .. 4) {
    my $pid = fork // die $!;
    if (!$pid) {
        my $c = Data::ReqRep::Shared::Client->new($p);
        while (time < $stop) { my $id = $c->send_wait('s' x 10, 1); $c->cancel($id) if defined $id }
        POSIX::_exit(0);
    }
    push @kids, $pid;
}
my $drain = fork // die $!;
if (!$drain) {
    my $s = Data::ReqRep::Shared->new(@geom);
    while (time < $stop) { $s->recv_wait(0.1); sleep 0.002 }
    POSIX::_exit(0);
}
push @kids, $drain;
sleep 0.3;

my $c = Data::ReqRep::Shared::Client->new($p);
my $in = 0;
for (1 .. 5) {
    my $id = $c->send_wait('B' x 240, 3);
    next unless defined $id;
    $in++;
    $c->cancel($id);
}
is $in, 5, 'a request needing most of the arena gets in, every time, while small ones keep coming';

kill KILL => @kids;
waitpid $_, 0 for @kids;
for my $how (qw(killed timed_out)) {
    my $q = tempdir(CLEANUP => 1) . "/reserve_$how.shm";
    my $s = Data::ReqRep::Shared->new($q, 1024, 1024, 16, 256);
    my $c = Data::ReqRep::Shared::Client->new($q);
    my $queued = 0;
    $queued++ while defined $c->send('s' x 10);
    my $big = fork // die $!;
    if (!$big) {
        my $bc = Data::ReqRep::Shared::Client->new($q);
        $bc->send_wait('B' x 4090, $how eq 'killed' ? 30 : 0.1);
        sleep 30;
        POSIX::_exit(0);
    }
    sleep 0.3;
    if ($how eq 'killed') { kill KILL => $big; waitpid $big, 0 }
    $s->recv for 1 .. $queued;
    my ($sent, $t0) = (0, time);
    until ($sent or $how ne 'killed' or time - $t0 > 2) { $sent = defined $c->send('s' x 10); sleep 0.005 unless $sent }
    $sent ||= defined $c->send('s' x 10);
    ok $sent, $how eq 'killed' ? 'a sender killed while holding arena room for its request does not hold it for good'
                   : 'a sender whose wait for arena room timed out gives the room back at once';
    if ($how ne 'killed') { kill KILL => $big; waitpid $big, 0 }
}

# A sender that gives up while the queue mutex is held must still hand back the arena room it reserved.
{
    my $q = tempdir(CLEANUP => 1) . '/reserve.shm';
    my $s = Data::ReqRep::Shared->new($q, 16, 4, 64, 4096);
    my $c = Data::ReqRep::Shared::Client->new($q);
    ok defined $c->send('x' x 3000), 'a first request takes most of the arena';
    pipe my $r, my $w or die $!;
    my $giver = fork // die $!;
    if (!$giver) {
        close $r;
        my $mine = Data::ReqRep::Shared::Client->new($q);
        syswrite $w, 'x';
        $mine->send_wait('y' x 3000, 1.5);   # no room: reserves, waits, gives up
        POSIX::_exit(0);
    }
    close $w;
    sysread $r, my $go, 1;
    sleep 0.4;
    my $poke = sub { open my $fh, '+<', $q or die $!; binmode $fh; seek $fh, 192, 0; print {$fh} pack 'L', $_[0]; close $fh };
    $poke->(0x8000_0000 | $$);            # a live process holds the mutex and never lets go
    waitpid $giver, 0;
    $poke->(0);
    my $reserved = do { open my $fh, '<', $q or die $!; binmode $fh; seek $fh, 160, 0; read $fh, my $b, 4; unpack 'L', $b };
    is $reserved, 0, 'the room it reserved is free again';
    ok defined $c->send('z' x 900), '  and another client can send';

    my $parked = fork // die $!;
    if (!$parked) { Data::ReqRep::Shared::Client->new($q)->send_wait('w' x 3000, 5); POSIX::_exit(0) }
    sleep 0.4;
    kill 'STOP', $parked;                 # stopped, so only clear can give its room back
    my $held = do { open my $fh, '<', $q or die $!; binmode $fh; seek $fh, 160, 0; read $fh, my $b, 4; unpack 'L', $b };
    cmp_ok $held, '>', 0, 'a stopped sender holds room';
    $s->clear;
    $reserved = do { open my $fh, '<', $q or die $!; binmode $fh; seek $fh, 160, 0; read $fh, my $b, 4; unpack 'L', $b };
    is $reserved, 0, '  and clear leaves none reserved';
    kill 'CONT', $parked;
    kill 'KILL', $parked;
    waitpid $parked, 0;
}

# The reserver dies just before the receive that empties the queue, and no receive follows.
{
    my $q = tempdir(CLEANUP => 1) . '/reserver_dies.shm';
    my $s = Data::ReqRep::Shared->new($q, 16, 8, 64, 4096);
    my $waiters = sub { $s->stats->{send_waiters} };
    pipe my $ra, my $wa or die $!;
    my $reserver = fork // die $!;
    if (!$reserver) {
        close $ra;
        my $c = Data::ReqRep::Shared::Client->new($q);
        $c->send('x' x 2000);
        syswrite $wa, 'x';
        $c->send_wait('y' x 2500);           # does not fit beside the first: reserves and parks
        POSIX::_exit(0);
    }
    close $wa;
    sysread $ra, my $go, 1;
    my $t = time;
    sleep 0.001 until $waiters->() >= 1 or time - $t > 5;
    pipe my $rb, my $wb or die $!;
    my $refused = fork // die $!;
    if (!$refused) {
        close $rb;
        my $t0 = time;
        my $id = Data::ReqRep::Shared::Client->new($q)->send_wait('z' x 1600, 8);
        syswrite $wb, sprintf '%d %.3f', defined $id ? 1 : 0, time - $t0;
        POSIX::_exit(0);
    }
    close $wb;
    $t = time;
    sleep 0.001 until $waiters->() >= 2 or time - $t > 5;
    kill 'KILL', $reserver;
    waitpid $reserver, 0;
    $s->recv;                                # empties the queue; nothing is sent after it
    sysread $rb, my $out, 64;
    waitpid $refused, 0;
    my ($sent, $took) = split ' ', $out // '0 99';
    ok $sent && $took < 5, sprintf 'a sender refused by a reservation whose holder died gets in at its next tick (%.1f s)', $took;
}

{
    my $q = tempdir(CLEANUP => 1) . '/signals.shm';
    my @g = ($q, 64, 64, 16, 4096);
    my $s = Data::ReqRep::Shared->new(@g);
    my $stop = time + 15;
    my @k;
    for (1 .. 4) {
        my $pid = fork // die $!;
        if (!$pid) {
            my $sc = Data::ReqRep::Shared::Client->new($q);
            while (time < $stop) { my $id = $sc->send_wait('s' x 100, 1); $sc->cancel($id) if defined $id }
            POSIX::_exit(0);
        }
        push @k, $pid;
    }
    my $d = fork // die $!;
    if (!$d) {
        my $r = Data::ReqRep::Shared->new(@g);
        while (time < $stop) { $r->recv_wait(0.1); sleep 0.02 }
        POSIX::_exit(0);
    }
    push @k, $d;
    sleep 0.5;
    my $bc = Data::ReqRep::Shared::Client->new($q);
    local $SIG{ALRM} = sub { };
    setitimer(ITIMER_REAL, 0.01, 0.01);
    my $t0 = time;
    my $id = $bc->send_wait('B' x 3000, 8);
    my $took = time - $t0;
    setitimer(ITIMER_REAL, 0, 0);
    ok defined $id, sprintf 'a request needing most of the arena gets in under a 100 Hz signal (%.1f s)', $took;
    kill KILL => @k;
    waitpid $_, 0 for @k;
}

{
    my $q = tempdir(CLEANUP => 1) . '/die.shm';
    my $s = Data::ReqRep::Shared->new($q, 16, 8, 64, 4096);
    my $dc = Data::ReqRep::Shared::Client->new($q);
    my $reserved = sub { open my $fh, '<', $q or die $!; binmode $fh; seek $fh, 160, 0; read $fh, my $b, 4; unpack 'L', $b };
    for my $m (qw(send_wait send_wait_notify req req_wait)) {
        defined $dc->send('x' x 3000) or die 'prefill';
        my $held = -1;
        local $SIG{ALRM} = sub { $held = $reserved->(); die "boom\n" };
        setitimer(ITIMER_REAL, 0.2, 0);
        my $died = !eval { $dc->$m('y' x 3000, $m eq 'req' ? () : 5); 1 } && $@ eq "boom\n";
        setitimer(ITIMER_REAL, 0, 0);
        ok $died && $held > 0, "$m: the room stays held while a handler runs";
        ok $reserved->() == 0 && defined $dc->send('z' x 900), '  and a handler that dies gives it back';
        $s->clear;
    }
}

{
    my $q = tempdir(CLEANUP => 1) . '/nested.shm';
    my $s = Data::ReqRep::Shared->new($q, 16, 8, 64, 4096);
    my $c1 = Data::ReqRep::Shared::Client->new($q);
    my $c2 = Data::ReqRep::Shared::Client->new($q);
    defined $c1->send('x' x 3000) or die 'prefill';
    my $hb;
    local $SIG{ALRM} = sub { my $t0 = time; my $id = $c2->send_wait('hb', 2); $hb = defined $id ? time - $t0 : -1 };
    my $srvpid = fork // die $!;
    if (!$srvpid) {
        my $r = Data::ReqRep::Shared->new($q, 16, 8, 64, 4096);
        sleep 1.5;
        while (my @got = $r->recv_wait(1)) { sleep 0.1 }
        POSIX::_exit(0);
    }
    setitimer(ITIMER_REAL, 0.3, 0);
    my $id = $c1->send_wait('y' x 3000, 6);
    ok defined $hb && $hb >= 0 && $hb < 1, 'a handler sending on the same channel is not held back by its own reservation';
    ok defined $id, '  and the interrupted large request still gets in';
    kill KILL => $srvpid;
    waitpid $srvpid, 0;
}

done_testing;
