#!/usr/bin/env perl
# Benchmark: Data::ReqRep::Shared vs other IPC mechanisms
# Cross-process echo round-trip throughput
use strict;
use warnings;
use Time::HiRes qw(time);
use File::Temp 'tmpnam';
use Socket;
use IO::Socket::INET;
use POSIX ':sys_wait_h';

my $N = $ARGV[0] || 50_000;
my @sizes = (12, 1024);

sub fmt_rate {
    my $r = shift;
    return sprintf("%.1fM", $r / 1e6) if $r >= 1e6;
    return sprintf("%.1fK", $r / 1e3) if $r >= 1e3;
    return sprintf("%.0f", $r);
}

print "Cross-process echo round-trip, $N iterations\n\n";

# --- Data::ReqRep::Shared (Str) ---
for my $size (@sizes) {
    my $msg = "x" x $size;
    my $path = tmpnam();
    my $resp_size = $size + 64;

    require Data::ReqRep::Shared;
    require Data::ReqRep::Shared::Client;

    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, $resp_size);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..($N + 500)) {
            my ($r, $ri) = $srv->recv_wait(10.0);
            last unless defined $r;
            $srv->reply($ri, $r);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    $cli->req($msg) for 1..500;  # warmup

    my $t0 = time();
    $cli->req($msg) for 1..$N;
    my $el = time() - $t0;

    waitpid $pid, 0;
    printf "  %-32s %8s req/s  (%dB payload)\n",
        "Data::ReqRep::Shared", fmt_rate($N / $el), $size;
    $srv->unlink;
}

# --- Data::ReqRep::Shared::Int (lock-free) ---
{
    require Data::ReqRep::Shared::Int;
    require Data::ReqRep::Shared::Int::Client;

    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 64);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..($N + 1000)) {
            my ($v, $ri) = $srv->recv_wait(10.0);
            last unless defined $v;
            $srv->reply($ri, $v);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Int::Client->new($path);
    $cli->req(42) for 1..1000;

    my $t0 = time();
    $cli->req(42) for 1..$N;
    my $el = time() - $t0;

    waitpid $pid, 0;
    printf "  %-32s %8s req/s  (int64 payload)\n",
        "ReqRep::Int (lock-free)", fmt_rate($N / $el);
    $srv->unlink;
}

# --- Unix socketpair ---
print "\n";
for my $size (@sizes) {
    my $msg = "x" x $size;
    my $len = length $msg;

    socketpair(my $pa, my $pb, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $pa->autoflush(1);
    $pb->autoflush(1);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        close $pa;
        my $buf;
        while (sysread($pb, $buf, $len) == $len) {
            syswrite($pb, $buf, $len) == $len or last;
        }
        exit 0;
    }
    close $pb;

    # warmup
    for (1..500) {
        syswrite($pa, $msg, $len);
        my $buf;
        sysread($pa, $buf, $len);
    }

    my $t0 = time();
    for (1..$N) {
        syswrite($pa, $msg, $len);
        my $buf;
        sysread($pa, $buf, $len);
    }
    my $el = time() - $t0;

    close $pa;
    waitpid $pid, 0;
    printf "  %-32s %8s req/s  (%dB payload)\n",
        "Unix socketpair", fmt_rate($N / $el), $size;
}

# --- Unix socketpair via broker (client -> broker -> worker -> broker -> client) ---
print "\n";
for my $size (@sizes) {
    my $msg = "x" x $size;
    my $len = length $msg;

    # client <-> broker
    socketpair(my $cb_c, my $cb_b, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    # broker <-> worker
    socketpair(my $bw_b, my $bw_w, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $_->autoflush(1) for ($cb_c, $cb_b, $bw_b, $bw_w);

    # worker: read from bw_w, echo back
    my $worker = fork // die "fork: $!";
    if ($worker == 0) {
        close $cb_c; close $cb_b; close $bw_b;
        my $buf;
        while (sysread($bw_w, $buf, $len) == $len) {
            syswrite($bw_w, $buf, $len) == $len or last;
        }
        exit 0;
    }

    # broker: read from cb_b, forward to bw_b, read reply, forward back
    my $broker = fork // die "fork: $!";
    if ($broker == 0) {
        close $cb_c; close $bw_w;
        my $buf;
        while (sysread($cb_b, $buf, $len) == $len) {
            syswrite($bw_b, $buf, $len) == $len or last;
            sysread($bw_b, $buf, $len) == $len or last;
            syswrite($cb_b, $buf, $len) == $len or last;
        }
        exit 0;
    }
    close $cb_b; close $bw_b; close $bw_w;

    # warmup
    for (1..500) {
        syswrite($cb_c, $msg, $len);
        my $buf;
        sysread($cb_c, $buf, $len);
    }

    my $t0 = time();
    for (1..$N) {
        syswrite($cb_c, $msg, $len);
        my $buf;
        sysread($cb_c, $buf, $len);
    }
    my $el = time() - $t0;

    close $cb_c;
    waitpid $broker, 0;
    waitpid $worker, 0;
    printf "  %-32s %8s req/s  (%dB payload)\n",
        "Socketpair via broker", fmt_rate($N / $el), $size;
}

# --- Pipe pair ---
print "\n";
for my $size (@sizes) {
    my $msg = "x" x $size;
    my $len = length $msg;

    pipe(my $cr, my $pw) or die "pipe: $!";  # parent writes, child reads
    pipe(my $pr, my $cw) or die "pipe: $!";  # child writes, parent reads

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        close $pw; close $pr;
        my $buf;
        while (sysread($cr, $buf, $len) == $len) {
            syswrite($cw, $buf, $len) == $len or last;
        }
        exit 0;
    }
    close $cr; close $cw;

    for (1..500) {
        syswrite($pw, $msg, $len);
        my $buf;
        sysread($pr, $buf, $len);
    }

    my $t0 = time();
    for (1..$N) {
        syswrite($pw, $msg, $len);
        my $buf;
        sysread($pr, $buf, $len);
    }
    my $el = time() - $t0;

    close $pw; close $pr;
    waitpid $pid, 0;
    printf "  %-32s %8s req/s  (%dB payload)\n",
        "Pipe pair", fmt_rate($N / $el), $size;
}

# --- TCP loopback ---
print "\n";
for my $size (@sizes) {
    my $msg = "x" x $size;
    my $len = length $msg;

    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1,
    ) or die "listen: $!";
    my $port = $srv->sockport;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $conn = $srv->accept or exit 1;
        $conn->autoflush(1);
        my $buf;
        while (sysread($conn, $buf, $len) == $len) {
            syswrite($conn, $buf, $len) == $len or last;
        }
        exit 0;
    }

    my $conn = IO::Socket::INET->new(
        PeerAddr => "127.0.0.1:$port",
    ) or die "connect: $!";
    $conn->autoflush(1);

    for (1..500) {
        syswrite($conn, $msg, $len);
        my $buf;
        sysread($conn, $buf, $len);
    }

    my $t0 = time();
    for (1..$N) {
        syswrite($conn, $msg, $len);
        my $buf;
        sysread($conn, $buf, $len);
    }
    my $el = time() - $t0;

    close $conn;
    waitpid $pid, 0;
    printf "  %-32s %8s req/s  (%dB payload)\n",
        "TCP loopback", fmt_rate($N / $el), $size;
}

# --- SysV message queues (if available) ---
if (eval { require IPC::SysV; require IPC::Msg; 1 }) {
    print "\n";
    my $IPC_PRIVATE = IPC::SysV::IPC_PRIVATE();
    my $IPC_CREAT   = IPC::SysV::IPC_CREAT();
    my $S_IRUSR     = IPC::SysV::S_IRUSR();
    my $S_IWUSR     = IPC::SysV::S_IWUSR();
    my $flags = $IPC_CREAT | $S_IRUSR | $S_IWUSR;

    for my $size (@sizes) {
        my $msg = "x" x $size;
        my $len = length $msg;

        my $req_q = IPC::Msg->new($IPC_PRIVATE, $flags) or die "msgget: $!";
        my $rep_q = IPC::Msg->new($IPC_PRIVATE, $flags) or die "msgget: $!";

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $buf;
            for (1..($N + 500)) {
                $req_q->rcv($buf, $len + 64, 0) or last;
                $rep_q->snd(1, $buf) or last;
            }
            exit 0;
        }

        for (1..500) {
            $req_q->snd(1, $msg);
            my $buf;
            $rep_q->rcv($buf, $len + 64, 0);
        }

        my $t0 = time();
        for (1..$N) {
            $req_q->snd(1, $msg);
            my $buf;
            $rep_q->rcv($buf, $len + 64, 0);
        }
        my $el = time() - $t0;

        waitpid $pid, 0;
        $req_q->remove;
        $rep_q->remove;
        printf "  %-32s %8s req/s  (%dB payload)\n",
            "IPC::Msg (SysV)", fmt_rate($N / $el), $size;
    }
}

# --- MCE::Channel (req/rep via send/recv pair) ---
if (eval { require MCE::Channel; 1 }) {
    print "\n";
    for my $size (@sizes) {
        my $msg = "x" x $size;

        my $req_ch = MCE::Channel->new(impl => 'Simple');
        my $rep_ch = MCE::Channel->new(impl => 'Simple');

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..($N + 500)) {
                my $buf = $req_ch->recv;
                last unless defined $buf;
                $rep_ch->send($buf);
            }
            exit 0;
        }

        for (1..500) { $req_ch->send($msg); $rep_ch->recv }

        my $t0 = time();
        for (1..$N) { $req_ch->send($msg); $rep_ch->recv }
        my $el = time() - $t0;

        waitpid $pid, 0;
        printf "  %-32s %8s req/s  (%dB payload)\n",
            "MCE::Channel (Simple)", fmt_rate($N / $el), $size;
    }
}

# --- Forks::Queue (Shmem, two queues) ---
if (eval { require Forks::Queue; 1 }) {
    print "\n";
    for my $size (@sizes) {
        my $msg = "x" x $size;
        my $n = $N > 10_000 ? 10_000 : $N;  # Forks::Queue is slow, cap iterations

        my $req_q = Forks::Queue->new(impl => 'Shmem');
        my $rep_q = Forks::Queue->new(impl => 'Shmem');

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..($n + 100)) {
                my $buf = $req_q->dequeue;
                last unless defined $buf;
                $rep_q->enqueue($buf);
            }
            exit 0;
        }

        for (1..100) { $req_q->enqueue($msg); $rep_q->dequeue }

        my $t0 = time();
        for (1..$n) { $req_q->enqueue($msg); $rep_q->dequeue }
        my $el = time() - $t0;

        waitpid $pid, 0;
        printf "  %-32s %8s req/s  (%dB payload, %d iters)\n",
            "Forks::Queue (Shmem)", fmt_rate($n / $el), $size, $n;
    }
}

print "\nDone.\n";
