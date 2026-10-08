use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();
use Time::HiRes qw(time);

use Data::HashMap::Shared::SI;

# A SIGKILL'd child holding the read lock must not block the next write.
# Reader slots are 16 bytes (pid, rdepth, two reserved) at the u64 offset in
# header byte 80; reclaiming clears the pid without counting, so the proof is in
# the slots: one is held by a dead pid after the kill, none after the put. The
# children hammer keys() on 20,000 entries: it holds the read lock for the whole
# XSUB, which incr_by's few hundred nanoseconds under the lock never did.

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_dead_rdr') . '.shm' }

sub held_reader_slots {
    my ($path) = @_;
    open my $f, '<:raw', $path or die "open: $!";
    seek $f, 80, 0 or die "seek: $!";
    read $f, my $buf, 8;
    my ($slots_off) = unpack 'Q<', $buf;
    seek $f, $slots_off, 0 or die "seek: $!";
    read $f, my $slots, 1024 * 16;
    close $f;
    my $held = 0;
    for my $i (0 .. 1023) {
        my ($pid, $rdepth) = unpack 'L< L<', substr $slots, $i * 16, 8;
        $held++ if $pid && $rdepth;
    }
    return $held;
}

{
    my $path = tmpfile();
    my $m = Data::HashMap::Shared::SI->new($path, 100_000);
    $m->put("seed$_", $_) for 1 .. 20_000;

    # the write runs in a child: a wrlock that never returns sits inside the
    # XSUB, where SIGALRM is deferred, so an alarm here could not break the
    # hang; forked before the readers so its pid cannot be one of theirs
    pipe(my $go_r, my $go_w) or die "pipe: $!";
    my $writer = fork // die "fork: $!";
    if (!$writer) {
        close $go_w;
        my $w = Data::HashMap::Shared::SI->new($path, 100_000);
        sysread($go_r, my $go, 1);
        $w->put("after_kill", 42);             # a new key forces the write-lock path
        POSIX::_exit(0);
    }
    close $go_r;

    # children report after one completed keys() so the kill lands on hammering
    # ones; about half are inside the lock at any instant, so three attempts at
    # sixteen suffice
    my $N_CHILDREN = 16;
    my $kill_hammering_children = sub {
        pipe(my $ready_r, my $ready_w) or die "pipe: $!";
        my @pids;
        for (1 .. $N_CHILDREN) {
            my $pid = fork // die "fork: $!";
            if (!$pid) {
                close $ready_r;
                my $c = Data::HashMap::Shared::SI->new($path, 100_000);
                () = $c->keys;
                syswrite($ready_w, 'r') or POSIX::_exit(1);
                close $ready_w;
                while (1) { () = $c->keys }
                POSIX::_exit(0);
            }
            push @pids, $pid;
        }
        close $ready_w;
        {
            local $SIG{ALRM} = sub { kill 'KILL', @pids; die "children never reported ready\n" };
            alarm 20;
            my $got = 0;
            while ($got < $N_CHILDREN) {
                my $n = sysread($ready_r, my $b, $N_CHILDREN - $got);
                unless ($n) { kill 'KILL', @pids; die "a child died before reporting ready\n" }
                $got += $n;
            }
            alarm 0;
        }
        close $ready_r;
        select(undef, undef, undef, 0.05);     # the last reporter rejoins its loop

        kill 'KILL', @pids;
        waitpid($_, 0) for @pids;
        return held_reader_slots($path);
    };
    my ($held, $attempts) = (0, 0);
    while ($held < 1 && $attempts++ < 3) { $held = $kill_hammering_children->() }
    cmp_ok($held, '>=', 1, "the kill caught $held children holding the read lock (attempt $attempts)");

    # one FUTEX_WAIT timeout (~2s) plus slack bounds the write
    my $start = time;
    local $SIG{PIPE} = 'IGNORE';               # a writer that died early: EPIPE, not a signal death
    syswrite($go_w, 'g') == 1 or die "release: $!";
    close $go_w;
    my ($done, $status) = (0, -1);
    while (1) {
        if (waitpid($writer, POSIX::WNOHANG()) == $writer) { $done = 1; $status = $?; last }
        last if time - $start >= 10;
        select(undef, undef, undef, 0.01);
    }
    my $elapsed = time - $start;
    unless ($done) { kill 'KILL', $writer; waitpid $writer, 0 }

    ok($done && $status == 0, "the write op after dead readers completed (elapsed ${\ sprintf '%.2f', $elapsed }s)")
        or diag $done ? sprintf('writer exited with status 0x%04x (signal %d, exit %d)', $status, $status & 127, $status >> 8)
                      : "writer still stuck after ${elapsed}s";
    cmp_ok($elapsed, '<', 5, "recovery completed in <5s");
    is($m->get("after_kill"), 42, "post-recovery value is correct");
    is(held_reader_slots($path), 0, "the dead readers' slots were reclaimed by the write lock");

    unlink $path;
}

sub start_reader {
    my ($path) = @_;
    pipe my $r, my $w or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        close $r;
        my $c = Data::HashMap::Shared::SI->new($path, 1000);
        $c->incr('k');
        print $w "ok\n"; close $w;
        sleep 60; POSIX::_exit(0);
    }
    close $w; <$r>;
    return $pid;
}

# poked into the slot, since no kill lands reliably inside a lock
sub pin_read_lock {
    my ($path, $pid) = @_;
    open my $f, '+<:raw', $path or die "open: $!";
    seek $f, 80, 0 or die "seek: $!"; read $f, my $buf, 8;
    my ($slots_off) = unpack 'Q<', $buf;
    seek $f, $slots_off, 0 or die "seek: $!"; read $f, my $slots, 1024 * 16;
    my ($slot) = grep { unpack('L<', substr $slots, $_ * 16, 4) == $pid } 0 .. 1023;
    defined $slot or BAIL_OUT('the dead reader holds no slot');
    seek $f, $slots_off + $slot * 16 + 4, 0 or die "seek: $!";
    print $f pack 'L<', 1; close $f or die "close: $!";
}

# the put runs in a child under a deadline: a write lock that never comes fails,
# not hangs
sub put_in_child {
    my ($m, $setup) = @_;
    my $t0 = time;
    my $pid = fork // die "fork: $!";
    unless ($pid) { $setup->() if $setup; POSIX::_exit(eval { $m->put(after => 2); 1 } ? 0 : 3) }
    my ($reaped, $status) = (0, -1);
    for (1 .. 1000) {
        if (waitpid($pid, POSIX::WNOHANG()) == $pid) { ($reaped, $status) = (1, $?); last }
        Time::HiRes::sleep(0.01);
    }
    unless ($reaped) { kill 'KILL', $pid; waitpid $pid, 0 }
    return ($status == 0, time - $t0);
}

# an unreaped killed reader is a zombie that kill($pid, 0) still reports alive;
# only /proc/<pid>/stat tells it from a live process
SKIP: {
    skip 'needs a readable /proc/<pid>/stat', 4 unless -r "/proc/$$/stat";
    my $path = tmpfile();
    my $m = Data::HashMap::Shared::SI->new($path, 1000);
    $m->put(k => 1);
    my $zpid = start_reader($path);
    kill 'KILL', $zpid;
    my $state = '';
    for (1 .. 200) {
        open my $s, '<', "/proc/$zpid/stat" or last;
        $state = (split ' ', scalar <$s>)[2];
        last if $state eq 'Z';
        Time::HiRes::sleep(0.01);
    }
    pin_read_lock($path, $zpid);
    my ($ok, $elapsed) = put_in_child($m);
    is($state, 'Z', 'the killed reader is an unreaped zombie');
    ok($ok, "a write past it completes (elapsed ${\ sprintf '%.2f', $elapsed }s)");
    is($m->get('after'), 2, '  ... and stores its value');
    is(held_reader_slots($path), 0, "  ... reclaiming the zombie's slot");
    waitpid $zpid, 0;
    unlink $path;
}

# each signal restarts the writer's first drain wait, so a writer taking signals
# faster than that wait must probe on a signal too, or it never gets past a dead
# reader
{
    my $path = tmpfile();
    my $m = Data::HashMap::Shared::SI->new($path, 1000);
    $m->put(k => 1);
    my $dpid = start_reader($path);
    kill 'KILL', $dpid;
    waitpid $dpid, 0;
    pin_read_lock($path, $dpid);
    my ($ok, $elapsed) = put_in_child($m, sub {
        $SIG{ALRM} = sub { };
        Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0.005, 0.005);
    });
    ok($ok, "a writer signalled every 5 ms gets past a dead reader (elapsed ${\ sprintf '%.2f', $elapsed }s)");
    is($m->get('after'), 2, '  ... and stores its value');
    is(held_reader_slots($path), 0, "  ... reclaiming the dead reader's slot");
    unlink $path;
}

done_testing;
