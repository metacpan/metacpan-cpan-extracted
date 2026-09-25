use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Time::HiRes qw(time sleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# Parked callers run in children, so a regression fails instead of hanging.

my $dir = tempdir(CLEANUP => 1);
my %kind = (
    Str => { server => sub { Data::ReqRep::Shared->new($_[0], 16, $_[1], 64) },
             client => sub { Data::ReqRep::Shared::Client->new($_[0]) }, msg => 'x' },
    Int => { server => sub { Data::ReqRep::Shared::Int->new($_[0], 16, $_[1]) },
             client => sub { Data::ReqRep::Shared::Int::Client->new($_[0]) }, msg => 7 },
);

sub within {
    my ($secs, $cond) = @_;
    my $end = time + $secs;
    my $v;
    sleep 0.02 until ($v = $cond->()) || time > $end;
    return $v;
}

sub parked_sender {
    my ($k, $p) = @_;
    my $pid = fork // die $!;
    if (!$pid) { POSIX::_exit(defined $k->{client}->($p)->send_wait($k->{msg}) ? 0 : 1) }
    return $pid;
}

# How many of @pids exit successfully within $secs; the rest are killed.
sub succeed_within {
    my ($secs, @pids) = @_;
    my %left = map { $_ => 1 } @pids;
    my $ok = 0;
    within($secs, sub {
        for my $pid (keys %left) {
            next unless waitpid($pid, POSIX::WNOHANG()) > 0;
            delete $left{$pid};
            $ok++ if $? == 0;
        }
        !%left;
    });
    for (keys %left) { kill KILL => $_; waitpid $_, 0 }
    return $ok;
}

for my $name (qw(Str Int)) {
    my $k = $kind{$name};

    subtest "$name: a sender parked for a slot wakes when the holders die" => sub {
        my $p = "$dir/dead_$name.shm";
        my $srv = $k->{server}->($p, 2);
        my @holders = map {
            my $pid = fork // die $!;
            if (!$pid) { my $c = $k->{client}->($p); $c->send($k->{msg}); sleep 60; POSIX::_exit(0) }
            $pid;
        } 1 .. 2;
        within(5, sub { $srv->size == 2 }) or diag 'holders never sent';
        my $w = parked_sender($k, $p);
        within(5, sub { $srv->stats->{slot_waiters} }) or diag 'sender never parked';
        kill KILL => @holders;
        waitpid $_, 0 for @holders;
        is succeed_within(6, $w), 1, 'it gets a slot without waiting for a release';
    };

    subtest "$name: back-to-back sends recover every slot the dead left" => sub {
        my $p = "$dir/burst_$name.shm";
        my $srv = $k->{server}->($p, 4);
        for (1 .. 4) {
            my $pid = fork // die $!;
            if (!$pid) { my $c = $k->{client}->($p); $c->send($k->{msg}); POSIX::_exit(0) }
            waitpid $pid, 0;
        }
        my $c = $k->{client}->($p);
        is scalar(grep { defined $c->send($k->{msg}) } 1 .. 4), 4, 'four sends in a row get four slots';
    };

    subtest "$name: a slot held by a child forked after the parent used the channel is recovered" => sub {
        my $p = "$dir/fork_$name.shm";
        my $srv = $k->{server}->($p, 1);
        my $c = $k->{client}->($p);
        my $id = $c->send($k->{msg});
        my ($m, $rid) = $srv->recv;
        $srv->reply($rid, $m);
        $c->get($id);
        my $pid = fork // die $!;
        if (!$pid) { $c->send($k->{msg}); POSIX::_exit(0) }
        waitpid $pid, 0;
        ok defined $c->send($k->{msg}), 'the parent gets the slot the dead child held';
    };

    subtest "$name: clear wakes every parked sender" => sub {
        my $p = "$dir/clear_$name.shm";
        my $srv = $k->{server}->($p, 4);
        my $holder = fork // die $!;
        if (!$holder) { my $c = $k->{client}->($p); $c->send($k->{msg}) for 1 .. 4; sleep 60; POSIX::_exit(0) }
        within(5, sub { $srv->size == 4 }) or diag 'holder never sent';
        my @w = map { parked_sender($k, $p) } 1 .. 4;
        within(5, sub { $srv->stats->{slot_waiters} == 4 }) or diag 'senders never parked';
        $srv->clear;
        is succeed_within(1, @w), 4, 'all of them get a slot at once';
        kill KILL => $holder;
        waitpid $holder, 0;
    };
}

for my $mode (qw(drain recv_multi recv_wait_multi arena)) {
    subtest "Str: $mode releases every sender it made room for" => sub {
        my $arena = $mode eq 'arena';
        my $srv = $arena ? Data::ReqRep::Shared->new_memfd('bw', 64, 64, 16, 4096)
                         : Data::ReqRep::Shared->new_memfd('bw', 4, 64, 16);
        my $fill = Data::ReqRep::Shared::Client->new_from_fd($srv->memfd);
        if ($arena) { $fill->send('F' x 4088) } else { $fill->send("fill$_") for 1 .. 4 }
        my $m = $arena ? 'x' x 64 : 'x';
        ok !defined $fill->send($m), 'the queue is full';
        my @kids;
        for (1 .. 6) {
            pipe my $r, my $w or die $!;
            my $pid = fork // die $!;
            if (!$pid) {
                close $r;
                my $c = Data::ReqRep::Shared::Client->new_from_fd($srv->memfd);
                my $id = $c->send_wait($m, 2);
                syswrite $w, sprintf "%d %.3f\n", defined $id ? 1 : 0, time;
                POSIX::_exit(0);
            }
            close $w;
            push @kids, [$pid, $r];
        }
        within(3, sub { $srv->stats->{send_waiters} == 6 }) or diag 'senders did not all park';
        my $t_free = time;
        if    ($mode eq 'drain')           { my @x = $srv->drain }
        elsif ($mode eq 'recv_multi')      { my @x = $srv->recv_multi(4) }
        elsif ($mode eq 'recv_wait_multi') { my @x = $srv->recv_wait_multi(4, 1) }
        else                               { my @x = $srv->recv }
        my $quick = 0;
        for my $k (@kids) {
            waitpid $k->[0], 0;
            my ($ok, $t) = split ' ', readline $k->[1];
            $quick++ if $ok && $t - $t_free < 0.8;
        }
        is $quick, $arena ? 6 : 4, $arena ? 'all six fit and all six go at once' : 'four fit and four go at once';
    };
}

for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    subtest "$name: a waiter gives up when the process that received its request dies" => sub {
        my $p = "$dir/dead_receiver_$name.shm";
        my $srv = $k->{server}->($p, 1);
        my $waiter = fork // die $!;
        if (!$waiter) {
            my $r = $k->{client}->($p)->req($k->{msg});
            POSIX::_exit(defined $r ? 1 : 0);
        }
        my $worker = fork // die $!;
        if (!$worker) { my @m = $k->{server}->($p, 1)->recv_wait(5); POSIX::_exit(@m ? 0 : 3) }
        waitpid $worker, 0;
        is $?, 0, 'the worker took the request and exited without replying';
        is succeed_within(8, $waiter), 1, 'req() with no timeout returns undef instead of waiting for ever';
        ok defined $k->{client}->($p)->send($k->{msg}), '  and the slot is free again';
    };

    subtest "$name: only the process that received a request may reply to it" => sub {
        my $p = "$dir/same_process_$name.shm";
        my $srv = $k->{server}->($p, 1);
        my $cli = $k->{client}->($p);
        my $id = $cli->send($k->{msg});
        my (undef, $rid) = $srv->recv;
        my $other = fork // die $!;
        if (!$other) { POSIX::_exit($k->{server}->($p, 1)->reply($rid, $k->{msg}) ? 1 : 0) }
        waitpid $other, 0;
        is $?, 0, 'a reply from another process is refused';
        ok $srv->reply($rid, $k->{msg}), 'the receiving process replies';
        is $cli->get_wait($id, 2), $k->{msg}, '  and the client gets that reply';
    };
}

subtest 'Str: arena room reserved for a large send is held only while it waits' => sub {
    {
        my $s = Data::ReqRep::Shared->new_memfd('gave_up', 16, 8, 16, 4096);
        my $big = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        my $small = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $small->send('f' x 8);
        ok !defined $big->send_wait('B' x 4090, 0.2), 'a large send gives up waiting for arena room';
        $s->recv;
        ok defined $small->send('s'), '  and the room it reserved is free again';
    }
    {
        my $s = Data::ReqRep::Shared->new_memfd('refused', 16, 8, 16, 4096);
        my $big = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        my $small = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $small->send('f' x 8);
        ok !defined $big->send('B' x 4090), 'a large send that does not wait is refused';
        $s->recv;
        ok defined $small->send('s'), '  and reserves no room';
    }
    {
        my $s = Data::ReqRep::Shared->new_memfd('died', 16, 8, 16, 4096);
        my $small = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $small->send('f' x 8);
        my $pid = fork // die $!;
        if (!$pid) { Data::ReqRep::Shared::Client->new_from_fd($s->memfd)->send_wait('B' x 4090); POSIX::_exit(0) }
        ok within(60, sub { $s->stats->{send_waiters} }), 'a large sender parks holding room';
        kill KILL => $pid;
        waitpid $pid, 0;
        $s->recv;
        ok defined $small->send_wait('s', 10), 'a send gets past room reserved by a sender killed while waiting';
    }
    {
        my $s = Data::ReqRep::Shared->new_memfd('used', 16, 8, 16, 4096);
        my $small = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $small->send('f' x 8);
        pipe my $sent_r, my $sent_w or die $!;
        pipe my $done_r, my $done_w or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $sent_r; close $done_w;
            my $ok = defined Data::ReqRep::Shared::Client->new_from_fd($s->memfd)->send_wait('B' x 4090, 60);
            syswrite $sent_w, $ok ? 1 : 0;
            sysread $done_r, my $go, 1;
            POSIX::_exit(0);
        }
        close $sent_w; close $done_r;
        ok within(30, sub { $s->stats->{send_waiters} }), 'a large sender parks holding room';
        $s->recv;
        sysread $sent_r, my $ok, 1;
        is $ok, 1, 'a large send gets in once room is made';
        $s->recv;
        ok defined $small->send('s'), '  and the room it reserved is not held after';
        syswrite $done_w, 1;
        waitpid $pid, 0;
    }
};

subtest 'a waiter gives up on a request its receiver took but died before marking' => sub {
    my @waiters;
    for my $name (qw(Str Int)) {
        my $k = $kind{$name};
        my $p = "$dir/unmarked_$name.shm";
        my $srv = $k->{server}->($p, 1);
        pipe my $sent_r, my $sent_w or die $!;
        pipe my $go_r, my $go_w or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $sent_r; close $go_w;
            my $c = $k->{client}->($p);
            my $id = $c->send($k->{msg});
            syswrite $sent_w, 1;
            sysread $go_r, my $go, 1;
            POSIX::_exit(defined $c->get_wait($id) ? 1 : 0);
        }
        close $sent_w; close $go_r;
        is sysread($sent_r, my $sent, 1), 1, "$name waiter sent";
        open my $fh, '+<', $p or die $!;
        binmode $fh;
        poke($fh, 64, 'Q', 1);
        close $fh;
        syswrite $go_w, 1;
        push @waiters, $pid;
    }
    is succeed_within(12, @waiters), 2, 'get_wait with no timeout returns undef instead of waiting for ever';
};

for my $name (qw(Str Int)) {
    my $int = $name eq 'Int';
    my $msg = $int ? 7 : 'x';
    subtest "$name: a waiter killed while parked stops being counted once wakes find nobody" => sub {
        my $p = "$dir/stale_waiter_$name.shm";
        my $srv = $int ? Data::ReqRep::Shared::Int->new($p, 2, 3) : Data::ReqRep::Shared->new($p, 2, 3, 64);
        my $cc = $int ? 'Data::ReqRep::Shared::Int::Client' : 'Data::ReqRep::Shared::Client';
        my $round_trips = sub {
            my $cli = $cc->new($p);
            for (1 .. 32) {
                my $id = $cli->send($msg) // return 0;
                my (undef, $rid) = $srv->recv or return 0;
                $srv->reply($rid, $msg);
                defined $cli->get($id) or return 0;
            }
            1;
        };
        my $killed_while = sub {
            my ($counter, $park) = @_;
            my $pid = fork // die $!;
            if (!$pid) { $park->(); POSIX::_exit(0) }
            within(5, sub { $srv->stats->{$counter} }) or diag "never parked for $counter";
            kill KILL => $pid;
            waitpid $pid, 0;
        };

        $killed_while->(recv_waiters => sub { $srv->recv_wait });
        ok $round_trips->(), 'traffic flows past a dead receiver';
        is $srv->stats->{recv_waiters}, 0, '  and recv_waiters drops back to 0';

        my $cli = $cc->new($p);
        my @queued = map { $cli->send($msg) } 1 .. 2;
        $killed_while->(send_waiters => sub { $cc->new($p)->send_wait($msg) });
        for (@queued) { my (undef, $rid) = $srv->recv; $srv->reply($rid, $msg); $cli->get($_) }
        ok $round_trips->(), 'traffic flows past a dead sender parked for queue room';
        is $srv->stats->{send_waiters}, 0, '  and send_waiters drops back to 0';

        my @held = map { my $id = $cli->send($msg); [$id, ($srv->recv)[1]] } 1 .. 3;
        $killed_while->(slot_waiters => sub { $cc->new($p)->send_wait($msg) });
        for (@held) { $srv->reply($_->[1], $msg); $cli->get($_->[0]) }
        ok $round_trips->(), 'traffic flows past a dead sender parked for a slot';
        is $srv->stats->{slot_waiters}, 0, '  and slot_waiters drops back to 0';

        my $pid = fork // die $!;
        if (!$pid) { my @m = $srv->recv_wait(30); POSIX::_exit(@m ? 0 : 1) }
        ok within(20, sub { $srv->stats->{recv_waiters} }), 'a receiver parks';
        $cli->send($msg);
        waitpid $pid, 0;
        is $?, 0, 'a parked receiver takes a request';
        is $srv->stats->{recv_waiters}, 0, '  and is no longer counted';
    };
}

# Int queue states a process killed mid-operation leaves: poke them into a fresh file.
{
    my %state = (
        'a producer killed between claiming a queue position and publishing it'
            => sub { my $fh = shift; seek $fh, 128, 0; print {$fh} pack 'Q', 1 },
        'a receiver killed between taking a message and moving the head past it'
            => sub { my $fh = shift; seek $fh, 256, 0; print {$fh} pack 'Q', 4; seek $fh, 128, 0; print {$fh} pack 'Q', 1 },
    );
    for my $what (sort keys %state) {
        subtest "Int: $what does not wedge the queue" => sub {
            my $p = "$dir/hole.shm";
            unlink $p;
            my $srv = Data::ReqRep::Shared::Int->new($p, 4, 4);
            open my $fh, '+<', $p or die $!;
            binmode $fh;
            $state{$what}->($fh);
            close $fh;
            my $cli = Data::ReqRep::Shared::Int::Client->new($p);
            my ($sent, $got) = (0, 0);
            for my $v (1 .. 20) {
                my $id = $cli->send_wait($v, 2) // last;
                $sent++;
                my ($req, $rid) = $srv->recv_wait(2);
                last unless defined $req && $req == $v;
                $srv->reply($rid, $v);
                $got++ if ($cli->get_wait($id, 2) // 0) == $v;
            }
            is $sent, 20, 'every send gets in, lap after lap';
            is $got, 20, '  and every request is received in order and answered';
        };
    }
}

for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    subtest "$name: destroying a client gives up its requests still in flight" => sub {
        my $p = "$dir/destroy_$name.shm";
        my $srv = $k->{server}->($p, 3);
        my $cli = $k->{client}->($p);
        my @ids = map { $cli->send($k->{msg}) } 1 .. 3;
        my (undef, $replied) = $srv->recv;
        $srv->reply($replied, $k->{msg});
        my (undef, $received) = $srv->recv;
        undef $cli;
        my $next = $k->{client}->($p);
        is scalar(grep { defined } map { $next->send($k->{msg}) } 1 .. 3), 3, 'another client gets all three slots at once';
        ok !$srv->reply($received, $k->{msg}), '  and a reply to a request it gave up is refused';
    };
}

# A dead process's pid went to another: poke that state, with this process as the newcomer.
sub peek32 { my ($fh, $off) = @_; seek $fh, $off, 0; read $fh, my $b, 4; unpack 'L', $b }
sub poke { my ($fh, $off, $fmt, @v) = @_; seek $fh, $off, 0; print {$fh} pack $fmt, @v }
sub reused_pid_file {
    my ($path, $int) = @_;
    unlink $path;
    my $srv = $int ? Data::ReqRep::Shared::Int->new($path, 16, 1) : Data::ReqRep::Shared->new($path, 16, 1, 64);
    open my $fh, '+<', $path or die $!;
    binmode $fh;
    my ($proc_off, $proc_slots) = (peek32($fh, 172), peek32($fh, 176));
    poke($fh, $proc_off + 8 * ($$ & ($proc_slots - 1)), 'LL', $$, 12345);
    return ($srv, $fh);
}

for my $name (qw(Str Int)) {
    subtest "$name: a slot held by a dead process whose pid was reused is recovered" => sub {
        my $p = "$dir/reuse_slot_$name.shm";
        my ($srv, $fh) = reused_pid_file($p, $name eq 'Int');
        my $gen = 3;
        poke($fh, peek32($fh, 44), 'Q', $gen << 32 | ($$ & 0xFFFFFF) << 8 | ($gen & 31) << 3 | 1);
        close $fh;
        my $pid = fork // die $!;
        if (!$pid) { POSIX::_exit(defined $kind{$name}{client}->($p)->send($kind{$name}{msg}) ? 0 : 1) }
        waitpid $pid, 0;
        is $?, 0, 'another process gets the only slot';
    };
}

subtest 'Str: the process that got the pid of one that died holding the queue mutex can lock it' => sub {
    my $p = "$dir/reuse_mutex.shm";
    my ($srv, $fh) = reused_pid_file($p, 0);
    poke($fh, 192, 'L', 0x8000_0000 | $$);
    close $fh;
    my $t0 = time;
    ok defined Data::ReqRep::Shared::Client->new($p)->send('x'), 'a send gets through';
    cmp_ok time - $t0, '<', 1, '  at once';
};

# kill() still finds these receivers, so the caller has to look in /proc once a tick passes.
for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    for my $reused (0, 1) {
        my $how = $reused ? 'died and its pid was reused' : 'died unreaped';
        subtest "$name: a caller gives up on a receiver that $how" => sub {
            my $p = "$dir/gone_${name}_$reused.shm";
            my $srv = $k->{server}->($p, 4);
            my $cli = $k->{client}->($p);
            my $id = $cli->send($k->{msg});
            pipe my $r, my $w or die $!;
            my $pid = fork // die $!;
            if (!$pid) {
                close $r;
                $k->{server}->($p, 4)->recv;
                syswrite $w, 'x';
                sleep 30 if $reused;
                POSIX::_exit(0);
            }
            close $w;
            sysread $r, my $got, 1;
            if ($reused) {
                open my $fh, '+<', $p or die $!;
                binmode $fh;
                my ($proc_off, $proc_slots) = (peek32($fh, 172), peek32($fh, 176));
                my ($entry) = grep { peek32($fh, $_) == $pid }
                    map { $proc_off + 8 * (($pid + $_) & ($proc_slots - 1)) } 0 .. 31;
                poke($fh, $entry + 4, 'L', 12345);
                close $fh;
            }
            my $t0 = time;
            ok !defined $cli->get_wait($id, 10), 'the wait ends without a reply';
            cmp_ok time - $t0, '<', 6, '  a tick or two later, not at its timeout';
            kill 'KILL', $pid;
            waitpid $pid, 0;
        };
    }
}

# A full registry: a newcomer may take only a record whose pid no process holds.
for my $live (0, 1) {
    my $how = $live ? 'whose pid a live process holds keeps its record' : 'that is gone gives its record to a newcomer';
    subtest "Str: a slot holder $how" => sub {
        my $p = "$dir/evict_$live.shm";
        my $srv = Data::ReqRep::Shared->new($p, 16, 1, 64);
        pipe my $r, my $w or die $!;
        my $holder = fork // die $!;
        if (!$holder) {
            my $c = Data::ReqRep::Shared::Client->new($p);
            $c->send('x') // POSIX::_exit(1);
            syswrite $w, 'x';
            sleep 60 if $live;
            POSIX::_exit(0);
        }
        close $w;
        sysread $r, my $got, 1;
        waitpid $holder, 0 unless $live;
        open my $fh, '+<', $p or die $!;
        binmode $fh;
        my ($off, $n, $resp_off) = (peek32($fh, 172), peek32($fh, 176), peek32($fh, 44));
        my %at = map { peek32($fh, $off + 8 * $_) => $_ } 0 .. $n - 1;
        my $start = peek32($fh, $off + 8 * $at{$$} + 4);
        poke($fh, $off + 8 * $at{$holder} + 4, 'L', 12345) if $live;   # its pid is now another process's
        for my $i (0 .. $n - 1) { poke($fh, $off + 8 * $i, 'LL', $$, $start) unless peek32($fh, $off + 8 * $i) }
        close $fh;
        my $newcomer = fork // die $!;
        if (!$newcomer) { Data::ReqRep::Shared::Client->new($p); POSIX::_exit(0) }
        waitpid $newcomer, 0;
        open $fh, '<', $p or die $!;
        binmode $fh;
        if ($live) {
            is peek32($fh, $off + 8 * $at{$holder}), $holder, 'a newcomer leaves the record alone';
            ok defined Data::ReqRep::Shared::Client->new($p)->send('y'), '  and the slot still goes to the next sender';
            kill 'KILL', $holder;
            waitpid $holder, 0;
        } else {
            is peek32($fh, $off + 8 * $at{$holder}), $newcomer, 'a newcomer takes the record';
            is peek32($fh, $resp_off) & 7, 0, '  and frees the slot its pid held, before any send';
        }
        close $fh;
    };
}

subtest 'Str: a newcomer is recorded in the one free record, however far away' => sub {
    my $p = "$dir/far.shm";
    my $srv = Data::ReqRep::Shared->new($p, 16, 1, 64);
    pipe my $r, my $w or die $!;
    pipe my $r2, my $w2 or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        close $w; close $r2;
        sysread $r, my $go, 1;
        Data::ReqRep::Shared::Client->new($p);
        syswrite $w2, 'x';
        POSIX::_exit(0);
    }
    close $r; close $w2;
    open my $fh, '+<', $p or die $!;
    binmode $fh;
    my ($off, $n) = (peek32($fh, 172), peek32($fh, 176));
    my ($mine) = grep { peek32($fh, $off + 8 * $_) == $$ } 0 .. $n - 1;
    my $start = peek32($fh, $off + 8 * $mine + 4);
    my $free = ($pid + 100) & ($n - 1);
    $free = ($free + 1) & ($n - 1) while peek32($fh, $off + 8 * $free);
    for my $i (0 .. $n - 1) { poke($fh, $off + 8 * $i, 'LL', $$, $start) if $i != $free && !peek32($fh, $off + 8 * $i) }
    close $fh;
    syswrite $w, 'x';
    sysread $r2, my $done, 1;
    waitpid $pid, 0;
    open $fh, '<', $p or die $!;
    binmode $fh;
    is peek32($fh, $off + 8 * $free), $pid, 'the newcomer takes it';
};

# exec keeps the pid and its start time, so only the new program can tell the old one is gone.
for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    subtest "$name: a receiver that re-executes itself gives up the requests it held" => sub {
        my $p = "$dir/exec_$name.shm";
        my $srv = $k->{server}->($p, 4);
        my $cli = $k->{client}->($p);
        my $id = $cli->send($k->{msg});
        pipe my $r, my $w or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $r;
            $k->{server}->($p, 4)->recv;
            syswrite $w, 'x';
            my @args = ($p, 16, 4, $name eq 'Str' ? 64 : ());
            exec($^X, (map { "-I$_" } @INC), '-MData::ReqRep::Shared::Int', '-e',
                'my ($class, @a) = @ARGV; my $s = $class->new(@a); sleep 20', ref $srv, @args)
                or POSIX::_exit(1);
        }
        close $w;
        sysread $r, my $got, 1;
        my $t0 = time;
        ok !defined $cli->get_wait($id, 8), 'the wait ends without a reply';
        cmp_ok time - $t0, '<', 5, '  once the new program opens the channel, not at the timeout';
        kill 'KILL', $pid;
        waitpid $pid, 0;
    };
}

subtest 'Str: a process whose pid a dead one left mid-release keeps what it holds' => sub {
    my $p = "$dir/releasing.shm";
    my $srv = Data::ReqRep::Shared->new($p, 16, 1, 64);
    pipe my $r, my $w or die $!;
    pipe my $r2, my $w2 or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        close $w; close $r2;
        sysread $r, my $go, 1;
        my $c = Data::ReqRep::Shared::Client->new($p);
        $c->send('x') // POSIX::_exit(1);
        syswrite $w2, 'x';
        sleep 30;
        POSIX::_exit(0);
    }
    close $r; close $w2;
    open my $fh, '+<', $p or die $!;
    binmode $fh;
    my ($off, $n) = (peek32($fh, 172), peek32($fh, 176));
    poke($fh, $off + 8 * ($pid & ($n - 1)), 'LL', $pid, 0xFFFF_FFFF);
    close $fh;
    syswrite $w, 'x';
    sysread $r2, my $sent, 1;
    ok !defined Data::ReqRep::Shared::Client->new($p)->send('y'), 'another client cannot take its only slot';
    kill 'KILL', $pid;
    waitpid $pid, 0;
};

for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    subtest "$name: a client alternating short waits between requests notices a receiver that died unreaped" => sub {
        my $p = "$dir/alternate_$name.shm";
        my $srv = $k->{server}->($p, 4);
        my $cli = $k->{client}->($p);
        my @ids = map { $cli->send($k->{msg}) } 1 .. 2;
        pipe my $r, my $w or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $r;
            my $s = $k->{server}->($p, 4);
            $s->recv for @ids;
            syswrite $w, 'x';
            POSIX::_exit(0);
        }
        close $w;
        sysread $r, my $got, 1;
        my ($t0, $gave_up) = (time);
        while (!$gave_up && time - $t0 < 8) {
            for my $id (@ids) {
                my $t = time;
                $cli->get_wait($id, 0.3);
                if (time - $t < 0.2) { $gave_up = time - $t0; last }
            }
        }
        ok $gave_up, 'a wait gives up on it early' or diag 'still waiting after 8 s';
        cmp_ok $gave_up // 99, '<', 5, '  within a tick or two';
        waitpid $pid, 0;
    };

    subtest "$name: a wait polled in turn with another still looks for its own receiver" => sub {
        my $p = "$dir/probe_$name.shm";
        my $srv = $k->{server}->($p, 4);
        my $cli = $k->{client}->($p);
        my ($live_id, $dead_id) = map { $cli->send($k->{msg}) } 1 .. 2;
        pipe my $r, my $w or die $!;
        my $live = fork // die $!;
        if (!$live) {
            close $r;
            $k->{server}->($p, 4)->recv;
            syswrite $w, 'x';
            sleep 30;
            POSIX::_exit(0);
        }
        sysread $r, my $first, 1;
        my $dead = fork // die $!;
        if (!$dead) {
            close $r;
            $k->{server}->($p, 4)->recv;
            syswrite $w, 'y';
            POSIX::_exit(0);
        }
        close $w;
        sysread $r, my $second, 1;
        # The long wait ends right after each tick, so it is the one that would spend a probe
        # shared with the other; the short wait must still get one of its own.
        my ($t0, $gave_up) = (time);
        while (!$gave_up && time - $t0 < 10) {
            $cli->get_wait($live_id, 2);
            my $t = time;
            $cli->get_wait($dead_id, 0.05);
            $gave_up = time - $t0 if time - $t < 0.04;
        }
        ok $gave_up, 'the wait on the receiver that died unreaped gives up' or diag 'still waiting after 10 s';
        cmp_ok $gave_up // 99, '<', 6, '  though another wait shares the handle';
        kill 'KILL', $live;
        waitpid $_, 0 for $live, $dead;
    };
}

done_testing;
