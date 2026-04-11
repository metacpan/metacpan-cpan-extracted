use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Time::HiRes 'time';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $MSGS     = $ENV{STRESS_MSGS}     || 2_000;
my $WORKERS  = $ENV{STRESS_WORKERS}  || 4;
my $CLIENTS  = $ENV{STRESS_CLIENTS}  || 4;
my $CANCEL   = $ENV{STRESS_CANCEL}   || 20;  # cancel every Nth request

diag "stress: $CLIENTS clients x $MSGS msgs, $WORKERS workers, cancel every $CANCEL";

# ============================================================
# 1. High-volume MPMC: N clients, M workers, full round-trip
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4096, 256, 4096);

    # spawn workers
    my @wpids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            while (my ($req, $id) = $srv->recv_wait(10.0)) {
                $srv->reply($id, "w$w:$req");
            }
            exit 0;
        }
        push @wpids, $pid;
    }

    # spawn clients
    my @cpids;
    for my $c (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Client->new($path);
            my $ok = 0;
            my $cancel_ok = 0;
            for my $i (1..$MSGS) {
                if ($i % $CANCEL == 0) {
                    my $id = $cli->send_wait("c${c}m$i", 5.0);
                    if (defined $id) { $cli->cancel($id); $cancel_ok++ }
                } else {
                    my $resp = $cli->req_wait("c${c}m$i", 5.0);
                    $ok++ if defined $resp && $resp =~ /^w\d+:c${c}m${i}$/;
                }
            }
            my $expected = $MSGS - int($MSGS / $CANCEL);
            exit($ok == $expected ? 0 : 1);
        }
        push @cpids, $pid;
    }

    my $t0 = time;
    my $all_ok = 1;
    for my $pid (@cpids) {
        waitpid($pid, 0);
        $all_ok = 0 if ($? >> 8) != 0;
    }
    my $dt = time - $t0;
    waitpid($_, 0) for @wpids;

    ok $all_ok, "mpmc: all clients verified all responses";

    my $total = $CLIENTS * $MSGS;
    my $stats = $srv->stats;
    diag sprintf "total=%d requests=%d replies=%d recoveries=%d dt=%.1fs (%.0f req/s)",
        $total, $stats->{requests}, $stats->{replies}, $stats->{recoveries},
        $dt, $stats->{requests} / ($dt || 1);

    $srv->unlink;
}

# ============================================================
# 2. Batch recv under load: 1 server using recv_multi
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4096, 256, 4096);

    my @cpids;
    for my $c (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Client->new($path);
            for my $i (1..$MSGS) {
                $cli->req_wait("c${c}b$i", 10.0);
            }
            exit 0;
        }
        push @cpids, $pid;
    }

    # server uses recv_multi for throughput
    my $t0 = time;
    my $total = $CLIENTS * $MSGS;
    my $processed = 0;
    while ($processed < $total) {
        my @batch = $srv->recv_wait_multi(100, 5.0);
        last unless @batch;
        while (@batch) {
            my ($data, $id) = splice @batch, 0, 2;
            $srv->reply($id, "ok:$data");
            $processed++;
        }
    }
    my $dt = time - $t0;

    waitpid($_, 0) for @cpids;

    is $processed, $total, "batch recv: processed all $total requests";
    diag sprintf "batch: %d reqs in %.1fs (%.0f req/s)", $processed, $dt, $processed / ($dt || 1);

    $srv->unlink;
}

# ============================================================
# 3. Variable-size messages: verify data integrity
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 8192, 1 << 20);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($req, $id) = $srv->recv_wait(5.0)) {
            $srv->reply($id, $req);  # echo back
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    my $ok = 0;
    for my $i (1..($MSGS / 2)) {
        # variable size: 1 to 5000 bytes
        my $len = 1 + ($i * 37) % 5000;
        my $msg = chr(65 + ($i % 26)) x $len;
        my $resp = $cli->req_wait($msg, 5.0);
        $ok++ if defined $resp && $resp eq $msg;
    }

    waitpid $pid, 0;
    is $ok, $MSGS / 2, "variable-size: all messages echoed correctly";

    $srv->unlink;
}

# ============================================================
# 4. eventfd notification under load
# ============================================================
{
    my $srv = Data::ReqRep::Shared->new_memfd("stress_efd", 1024, 64, 4096);
    my $req_fd = $srv->eventfd;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # EV-less server: select on eventfd
        my $processed = 0;
        while ($processed < $MSGS) {
            my $rin = '';
            vec($rin, $req_fd, 1) = 1;
            select($rin, undef, undef, 5.0) or last;
            $srv->eventfd_consume;
            while (my ($req, $id) = $srv->recv) {
                $srv->reply($id, "ok");
                $processed++;
            }
        }
        exit 0;
    }

    my $fd = $srv->memfd;
    my $cli = Data::ReqRep::Shared::Client->new_from_fd($fd);
    $cli->req_eventfd_set($req_fd);

    my $ok = 0;
    for my $i (1..$MSGS) {
        my $id = $cli->send_wait_notify("m$i", 5.0);
        next unless defined $id;
        my $resp = $cli->get_wait($id, 5.0);
        $ok++ if defined $resp && $resp eq "ok";
    }

    waitpid $pid, 0;
    is $ok, $MSGS, "eventfd under load: all $MSGS round-trips ok";
}

done_testing;
