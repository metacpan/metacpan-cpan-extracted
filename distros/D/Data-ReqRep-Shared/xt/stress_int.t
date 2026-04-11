use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Time::HiRes 'time';

use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $MSGS     = $ENV{STRESS_MSGS}     || 2_000;
my $WORKERS  = $ENV{STRESS_WORKERS}  || 4;
my $CLIENTS  = $ENV{STRESS_CLIENTS}  || 4;
my $CANCEL   = $ENV{STRESS_CANCEL}   || 20;

diag "int stress: $CLIENTS clients x $MSGS msgs, $WORKERS workers, cancel every $CANCEL";

# ============================================================
# 1. MPMC Int: N clients, M workers, full round-trip
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 4096, 256);

    my @wpids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            while (my ($v, $id) = $srv->recv_wait(10.0)) {
                $srv->reply($id, $v * 2);
            }
            exit 0;
        }
        push @wpids, $pid;
    }

    my @cpids;
    for my $c (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Int::Client->new($path);
            my $ok = 0;
            my $cancel_ok = 0;
            for my $i (1..$MSGS) {
                my $val = $c * 100000 + $i;
                if ($i % $CANCEL == 0) {
                    my $id = $cli->send_wait($val, 5.0);
                    if (defined $id) { $cli->cancel($id); $cancel_ok++ }
                } else {
                    my $resp = $cli->req_wait($val, 5.0);
                    $ok++ if defined $resp && $resp == $val * 2;
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

    ok $all_ok, "int mpmc: all clients verified responses";

    my $s = $srv->stats;
    diag sprintf "requests=%d replies=%d recoveries=%d dt=%.1fs (%.0f req/s)",
        $s->{requests}, $s->{replies}, $s->{recoveries},
        $dt, $s->{requests} / ($dt || 1);

    $srv->unlink;
}

# ============================================================
# 2. Lock-free contention: many producers, one consumer
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 4096, 256);

    my @ppids;
    for my $p (1..$CLIENTS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Int::Client->new($path);
            for my $i (1..$MSGS) {
                $cli->req_wait($p * 100000 + $i, 10.0);
            }
            exit 0;
        }
        push @ppids, $pid;
    }

    # single server
    my $t0 = time;
    my $total = $CLIENTS * $MSGS;
    my $processed = 0;
    while ($processed < $total) {
        my ($v, $id) = $srv->recv_wait(5.0);
        last unless defined $v;
        $srv->reply($id, $v);
        $processed++;
    }
    my $dt = time - $t0;

    waitpid($_, 0) for @ppids;

    is $processed, $total, "int contention: single consumer processed all $total";
    diag sprintf "throughput: %.0f req/s", $processed / ($dt || 1);

    $srv->unlink;
}

# ============================================================
# 3. Variable values: verify no corruption under concurrency
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 64);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($v, $id) = $srv->recv_wait(5.0)) {
            $srv->reply($id, $v * 3 + 7);
        }
        exit 0;
    }

    my $cli = Data::ReqRep::Shared::Int::Client->new($path);
    my $ok = 0;
    for my $i (1..$MSGS) {
        my $val = $i * ($i % 2 ? 1 : -1);
        my $resp = $cli->req_wait($val, 10.0);
        $ok++ if defined $resp && $resp == ($val * 3 + 7);
    }

    waitpid $pid, 0;
    is $ok, $MSGS, "int variable values: all $ok correct (v*3+7 transform)";

    $srv->unlink;
}

# ============================================================
# 4. Slot exhaustion under load: resp_slots < concurrent clients
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 1024, 8);  # only 8 slots

    my $spid = fork // die "fork: $!";
    if ($spid == 0) {
        while (my ($v, $id) = $srv->recv_wait(10.0)) {
            $srv->reply($id, $v);
        }
        exit 0;
    }

    # 4 clients with 8 slots = contention on slots
    my @cpids;
    for my $c (1..4) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $cli = Data::ReqRep::Shared::Int::Client->new($path);
            my $ok = 0;
            for my $i (1..200) {
                my $resp = $cli->req_wait($c * 1000 + $i, 5.0);
                $ok++ if defined $resp && $resp == $c * 1000 + $i;
            }
            exit($ok == 200 ? 0 : 1);
        }
        push @cpids, $pid;
    }

    my $all_ok = 1;
    for my $pid (@cpids) {
        waitpid($pid, 0);
        $all_ok = 0 if ($? >> 8) != 0;
    }
    waitpid $spid, 0;

    ok $all_ok, "int slot contention: all clients succeeded with only 8 slots";
    $srv->unlink;
}

done_testing;
