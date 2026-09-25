use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Time::HiRes qw(time sleep);
use POSIX ();

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 4, 256);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    for my $trial (1..10) {
        my $id = $cli->send("race$trial");
        ok defined $id, "cancel+get race trial $trial: send ok";

        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            sleep(0.001 + rand() * 0.01);
            $cli->cancel($id);
            POSIX::_exit(0);
        }

        my $t0 = time;
        my $resp = $cli->get_wait($id, 2.0);
        my $dt = time - $t0;

        ok $dt < 2.0, sprintf("cancel+get race trial %d: unblocked in %.3fs", $trial, $dt);
        ok !defined $resp, "cancel+get race trial $trial: returns undef";

        waitpid $pid, 0;
    }

    while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
    $srv->unlink;
}

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
            $cli->cancel($id);
            POSIX::_exit(0);
        }

        my $ok = $srv->reply($ri, "resp$trial");
        waitpid $pid, 0;
        $ok ? $reply_won++ : $cancel_won++;
        ok !defined $cli->get($id), "cancel+reply race trial $trial: a cancelled request yields no reply";
    }
    is $cli->pending, 0, 'cancel+reply race: every slot came free';

    diag sprintf "cancel won %d/%d, reply won %d/%d",
        $cancel_won, 50, $reply_won, 50;

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 64, 16, 256);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my @ids;
    push @ids, $cli->send("clear$_") for 1..8;

    my @pids;
    for my $i (0..3) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $resp = $cli->get_wait($ids[$i], 5.0);
            POSIX::_exit(defined $resp ? 1 : 0);
        }
        push @pids, $pid;
    }

    # Give children time to enter get_wait
    sleep(0.05);

    my $t0 = time;
    $srv->clear;

    for my $pid (@pids) {
        waitpid $pid, 0;
        is $?, 0, "clear race: child $pid unblocked and got undef";
    }
    my $dt = time - $t0;
    ok $dt < 1, sprintf("clear race: all children unblocked in %.3fs", $dt);   # below the 2 s tick

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 256, 1, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $aba_detected = 0;
    my $ok_count = 0;

    for my $i (1..500) {
        my $id1 = $cli->send("first$i");
        next unless defined $id1;
        $cli->cancel($id1);

        my $id2 = $cli->send("second$i");
        next unless defined $id2;

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
