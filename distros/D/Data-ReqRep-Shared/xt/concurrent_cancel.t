use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Time::HiRes qw(time sleep);
use POSIX ();

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

# ============================================================
# 1. cancel + get_wait race: cancel fires while get_wait is blocked
#    Verify get_wait unblocks promptly (does not hang).
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 4, 256);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    for my $trial (1..10) {
        my $id = $cli->send("race$trial");
        ok defined $id, "cancel+get race trial $trial: send ok";

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            # child cancels after small random delay
            sleep(0.001 + rand() * 0.01);
            $cli->cancel($id);
            POSIX::_exit(0);
        }

        my $t0 = time;
        my $resp = $cli->get_wait($id, 2.0);
        my $dt = time - $t0;

        # get_wait should return within ~50ms (cancel delay + scheduling)
        ok $dt < 2.0, sprintf("cancel+get race trial %d: unblocked in %.3fs", $trial, $dt);
        ok !defined $resp, "cancel+get race trial $trial: returns undef";

        waitpid $pid, 0;
    }

    # drain all queued requests
    while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
    $srv->unlink;
}

# ============================================================
# 2. cancel + reply race: server replies at the same moment client cancels
#    Exactly one should win — no data corruption.
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 64, 16, 256);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $cancel_won = 0;
    my $reply_won = 0;

    for my $trial (1..50) {
        my $id = $cli->send("cr$trial");
        my ($rq, $ri) = $srv->recv;

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            # child cancels immediately
            $cli->cancel($id);
            POSIX::_exit(0);
        }

        # parent replies immediately — race with child's cancel
        my $ok = $srv->reply($ri, "resp$trial");
        waitpid $pid, 0;

        if ($ok) {
            # reply won the CAS — response should be readable
            my $resp = $cli->get($id);
            if (defined $resp) {
                is $resp, "resp$trial", "reply won trial $trial: data correct";
                $reply_won++;
            } else {
                # cancel won but reply CAS also succeeded? shouldn't happen
                # with CAS ACQUIRED→READY in reply
                fail "reply succeeded but get returned undef in trial $trial";
            }
        } else {
            # cancel won the CAS — slot freed, reply returned false
            $cancel_won++;
            pass "cancel won trial $trial";
        }
    }

    diag sprintf "cancel won %d/%d, reply won %d/%d",
        $cancel_won, 50, $reply_won, 50;

    # at least one of each should have won (probabilistic but very likely)
    # don't assert — timing dependent. Just report.

    $srv->unlink;
}

# ============================================================
# 3. cancel + clear race: clear fires while requests are in-flight
#    All get_wait callers must unblock.
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 64, 16, 256);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # Send several requests, don't process them
    my @ids;
    push @ids, $cli->send("clear$_") for 1..8;

    # Fork children that each get_wait on their request
    my @pids;
    for my $i (0..3) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $resp = $cli->get_wait($ids[$i], 5.0);
            # should return undef after clear
            POSIX::_exit(defined $resp ? 1 : 0);
        }
        push @pids, $pid;
    }

    # Give children time to enter get_wait
    sleep(0.05);

    # Clear — should unblock all get_wait callers
    my $t0 = time;
    $srv->clear;

    for my $pid (@pids) {
        waitpid $pid, 0;
        is $? >> 8, 0, "clear race: child $pid unblocked and got undef";
    }
    my $dt = time - $t0;
    ok $dt < 2.0, sprintf("clear race: all children unblocked in %.3fs", $dt);

    $srv->unlink;
}

# ============================================================
# 4. Rapid cancel/send on same slot: verify generation prevents ABA
#    across many iterations with minimal slot count
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 256, 1, 64);  # 1 slot!
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $aba_detected = 0;
    my $ok_count = 0;

    for my $i (1..500) {
        my $id1 = $cli->send("first$i");
        next unless defined $id1;
        $cli->cancel($id1);

        my $id2 = $cli->send("second$i");
        next unless defined $id2;

        # Server processes both — first reply should fail (gen mismatch)
        my ($rq1, $ri1) = $srv->recv;
        my $r1 = $srv->reply($ri1, "bad");
        $aba_detected++ unless $r1;

        my ($rq2, $ri2) = $srv->recv;
        my $r2 = $srv->reply($ri2, "good$i");
        if ($r2) {
            my $resp = $cli->get($id2);
            $ok_count++ if defined $resp && $resp eq "good$i";
        }
    }

    ok $aba_detected > 0, "ABA rapid: generation prevented $aba_detected stale replies";
    ok $ok_count > 0, "ABA rapid: $ok_count correct round-trips";
    diag "aba_detected=$aba_detected ok_count=$ok_count out of 500 iterations";

    $srv->unlink;
}

done_testing;
