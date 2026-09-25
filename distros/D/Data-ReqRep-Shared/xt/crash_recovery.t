use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX '_exit';
use IO::Pipe;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096, 1 << 20);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my $cli = Data::ReqRep::Shared::Client->new($path);
        # Fill the queue with large messages to hold the mutex longer
        my $big = "X" x 4000;
        print $pipe "go\n";
        $pipe->close;
        for (1..100000) {
            my $id = $cli->send($big);
            $cli->cancel($id) if defined $id;
        }
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;
    sleep(0.05);
    kill 9, $pid;
    waitpid($pid, 0);
    diag "child $pid killed";

    while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "stale") }

    my $cli = Data::ReqRep::Shared::Client->new($path);
    my $t0 = time;
    my $id = $cli->send_wait("after_crash", 10.0);
    my $dt = time - $t0;

    ok defined $id, 'mutex recovery: send succeeded after crash';
    my $stats = $srv->stats;
    diag sprintf "dt=%.2fs recoveries=%d requests=%d",
        $dt, $stats->{recoveries}, $stats->{requests};

    if ($stats->{recoveries} > 0) {
        ok $dt >= 1.5 && $dt < 10, sprintf('mutex recovered in %.2fs', $dt);
    } else {
        pass 'child completed before kill (timing-dependent)';
    }

    my ($req, $rid) = $srv->recv;
    is $req, 'after_crash', 'post-crash recv ok';
    $srv->reply($rid, 'recovered');
    is $cli->get($id), 'recovered', 'post-crash round-trip ok';

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 2, 64);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $cli = Data::ReqRep::Shared::Client->new($path);
        $cli->send("occupy1");
        $cli->send("occupy2");
        _exit(0);
    }
    waitpid($pid, 0);

    my $cli = Data::ReqRep::Shared::Client->new($path);
    my $id = $cli->send("after_slot_crash");

    ok defined $id, 'slot recovery: send succeeded after child crash';
    my $stats = $srv->stats;
    ok $stats->{recoveries} > 0, "slot recovery: recoveries=$stats->{recoveries}";

    while (my ($req, $rid) = $srv->recv) {
        my $ok = $srv->reply($rid, "re:$req");
        diag "recv '$req' reply_ok=$ok";
    }

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 256, 32, 4096, 1 << 20);

    for my $round (1..3) {
        my $pipe = IO::Pipe->new;
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $pipe->writer;
            my $cli = Data::ReqRep::Shared::Client->new($path);
            my $big = "Y" x 2000;
            print $pipe "go\n";
            $pipe->close;
            for (1..100000) {
                my $id = $cli->send($big);
                $cli->cancel($id) if defined $id;
            }
            _exit(0);
        }
        $pipe->reader;
        <$pipe>;
        $pipe->close;
        sleep(0.05);
        kill 9, $pid;
        waitpid($pid, 0);

        while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
        my $cli = Data::ReqRep::Shared::Client->new($path);
        my $t0 = time;
        my $id = $cli->send_wait("round$round", 10.0);
        my $dt = time - $t0;
        ok defined $id, sprintf("round %d: send ok (%.2fs)", $round, $dt);
        my ($rq, $ri) = $srv->recv;
        $srv->reply($ri, "ok");
        $cli->get($id);
    }

    my $stats = $srv->stats;
    diag sprintf "total recoveries: %d", $stats->{recoveries};
    $srv->unlink;
}

done_testing;
