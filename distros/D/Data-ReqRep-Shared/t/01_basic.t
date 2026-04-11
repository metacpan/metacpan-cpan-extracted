use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tmpnam();

# Create server
my $srv = Data::ReqRep::Shared->new($path, 16, 8, 1024);
ok $srv, 'server created';
is $srv->capacity, 16, 'capacity';
is $srv->resp_slots, 8, 'resp_slots';
is $srv->resp_size, 1024, 'resp_size';
is $srv->size, 0, 'empty queue';
ok $srv->is_empty, 'is_empty';

# Client opens existing
my $cli = Data::ReqRep::Shared::Client->new($path);
ok $cli, 'client created';
is $cli->resp_slots, 8, 'client sees resp_slots';
is $cli->capacity, 16, 'client sees capacity';
ok $cli->is_empty, 'client sees is_empty';

# Non-blocking recv on empty queue
my @r = $srv->recv;
is scalar @r, 0, 'recv on empty returns empty list';

# Send + recv + reply + get
my $id = $cli->send("hello");
ok defined $id, 'send returns id';
is $srv->size, 1, 'queue has 1 request';
is $cli->size, 1, 'client sees size';

my ($req, $rid) = $srv->recv;
is $req, 'hello', 'recv got request data';
is $rid, $id, 'recv got correct id';
is $srv->size, 0, 'queue empty after recv';

$srv->reply($rid, "world");
my $resp = $cli->get($id);
is $resp, 'world', 'got response';

# UTF-8 round-trip
{
    my $utf8_str = "\x{263A}";
    my $id2 = $cli->send($utf8_str);
    my ($req2, $rid2) = $srv->recv;
    ok utf8::is_utf8($req2), 'request preserved UTF-8 flag';
    is $req2, $utf8_str, 'request UTF-8 data matches';
    $srv->reply($rid2, $utf8_str);
    my $resp2 = $cli->get($id2);
    ok utf8::is_utf8($resp2), 'response preserved UTF-8 flag';
    is $resp2, $utf8_str, 'response UTF-8 data matches';
}

# Empty string
{
    my $id3 = $cli->send("");
    my ($req3, $rid3) = $srv->recv;
    is $req3, '', 'empty request';
    $srv->reply($rid3, "");
    my $resp3 = $cli->get($id3);
    is $resp3, '', 'empty response';
}

# Multiple concurrent requests
{
    my @ids;
    for my $i (1..4) {
        push @ids, $cli->send("req$i");
    }
    is $srv->size, 4, '4 pending requests';

    my @reqs;
    while (my ($rq, $ri) = $srv->recv) {
        push @reqs, [$rq, $ri];
    }
    is scalar @reqs, 4, 'received all 4';

    for my $i (0..3) {
        $srv->reply($reqs[$i][1], "resp" . ($i+1));
    }

    for my $i (0..3) {
        my $r = $cli->get($ids[$i]);
        is $r, "resp" . ($i+1), "response $i matches";
    }
}

# cancel — basic: reply to cancelled slot fails (state mismatch)
{
    my $cid = $cli->send("cancel_me");
    ok defined $cid, 'send for cancel';
    $cli->cancel($cid);
    my $cid2 = $cli->send("after_cancel");
    ok defined $cid2, 'send after cancel works';

    my ($crq, $cri) = $srv->recv;
    is $crq, 'cancel_me', 'cancelled request still in queue';
    my $ok = $srv->reply($cri, "x");
    ok !$ok, 'reply to cancelled slot returns false';

    ($crq, $cri) = $srv->recv;
    is $crq, 'after_cancel', 'after_cancel received';
    $srv->reply($cri, "y");
    is $cli->get($cid2), 'y', 'after_cancel response';
}

# cancel ABA — generation prevents reply to recycled slot
{
    # Use 1 resp_slot to force same-slot reuse
    my $aba_path = tmpnam();
    my $aba_srv = Data::ReqRep::Shared->new($aba_path, 8, 1, 256);
    my $aba_cli = Data::ReqRep::Shared::Client->new($aba_path);

    # Send request (acquires the only slot, gen=1)
    my $id1 = $aba_cli->send("first");
    ok defined $id1, 'ABA: first send ok';

    # Cancel frees the slot
    $aba_cli->cancel($id1);

    # Second send re-acquires same slot (gen=2)
    my $id2 = $aba_cli->send("second");
    ok defined $id2, 'ABA: second send ok';
    isnt $id1, $id2, 'ABA: different ids (same slot, different generation)';

    # Server recv gets "first" with old id (gen=1)
    my ($rq1, $ri1) = $aba_srv->recv;
    is $rq1, 'first', 'ABA: recv first';

    # Reply with old id fails — generation mismatch prevents writing to recycled slot
    my $ok = $aba_srv->reply($ri1, "wrong_reply");
    ok !$ok, 'ABA: reply with stale generation fails';

    # Server recv gets "second" with new id (gen=2)
    my ($rq2, $ri2) = $aba_srv->recv;
    is $rq2, 'second', 'ABA: recv second';
    $aba_srv->reply($ri2, "correct_reply");

    # Client gets response for second request
    my $resp = $aba_cli->get($id2);
    is $resp, 'correct_reply', 'ABA: correct response for second request';

    $aba_srv->unlink;
}

# cancel after reply arrived — cancel is no-op, get() still works
{
    my $lc_id = $cli->send("late_cancel");
    ok defined $lc_id, 'late_cancel: send ok';
    my ($lc_rq, $lc_ri) = $srv->recv;
    is $lc_rq, 'late_cancel', 'late_cancel: server received';
    $srv->reply($lc_ri, "late_reply");
    $cli->cancel($lc_id);  # no-op: slot is READY, CAS ACQUIRED→FREE fails
    my $lc_resp = $cli->get($lc_id);
    is $lc_resp, 'late_reply', 'late_cancel: get after cancel-on-READY works';
}

# cancel unblocks get_wait
{
    my $cw_path = tmpnam();
    my $cw_srv = Data::ReqRep::Shared->new($cw_path, 8, 4, 256);
    my $cw_cli = Data::ReqRep::Shared::Client->new($cw_path);

    my $cw_id = $cw_cli->send("cancel_wait");
    ok defined $cw_id, 'cancel_wait: send ok';

    my $pid = fork();
    if ($pid == 0) {
        # child: wait a bit, then cancel the request
        select(undef, undef, undef, 0.1);
        $cw_cli->cancel($cw_id);
        exit 0;
    }

    # parent: get_wait should unblock when child cancels
    my $cw_resp = $cw_cli->get_wait($cw_id, 2.0);
    ok !defined $cw_resp, 'cancel_wait: get_wait returns undef after cancel';

    waitpid $pid, 0;
    # drain the request from queue
    $cw_srv->recv;
    $cw_srv->unlink;
}

# Blocking recv_wait with timeout
{
    my @empty = $srv->recv_wait(0.01);
    is scalar @empty, 0, 'recv_wait times out on empty queue';
}

# send_wait + get_wait
{
    my $id4 = $cli->send_wait("blocking_req", 1.0);
    ok defined $id4, 'send_wait returns id';
    my ($rq4, $ri4) = $srv->recv_wait(1.0);
    is $rq4, 'blocking_req', 'recv_wait got data';
    $srv->reply($ri4, "blocking_resp");
    my $rsp4 = $cli->get_wait($id4, 1.0);
    is $rsp4, 'blocking_resp', 'get_wait got response';
}

# req (sync convenience) via fork
{
    my $pid = fork();
    if ($pid == 0) {
        my $child_srv = Data::ReqRep::Shared->new($path, 16, 8, 1024);
        for (1..3) {
            my ($rq, $ri) = $child_srv->recv_wait(2.0);
            last unless defined $rq;
            $child_srv->reply($ri, "reply:$rq");
        }
        exit 0;
    }

    my $cli2 = Data::ReqRep::Shared::Client->new($path);
    for my $i (1..3) {
        my $r = $cli2->req("msg$i");
        is $r, "reply:msg$i", "req() round-trip $i";
    }
    waitpid $pid, 0;
}

# stats — both server and client expose full stats
{
    my $s = $srv->stats;
    ok $s->{requests} > 0, 'srv stat requests > 0';
    ok $s->{replies} > 0, 'srv stat replies > 0';
    ok exists $s->{send_full}, 'srv stats has send_full';
    ok exists $s->{slot_waiters}, 'srv stats has slot_waiters';

    my $cs = $cli->stats;
    ok $cs->{requests} > 0, 'cli stat requests > 0';
    ok exists $cs->{send_full}, 'cli stats has send_full';
    ok exists $cs->{slot_waiters}, 'cli stats has slot_waiters';
}

# eventfd creation
{
    my $efd = $srv->eventfd;
    ok $efd >= 0, 'server eventfd created';
    is $srv->fileno, $efd, 'server fileno matches';
    my $rfd = $srv->reply_eventfd;
    ok $rfd >= 0, 'server reply_eventfd created';
    is $srv->reply_fileno, $rfd, 'server reply_fileno matches';

    my $cefd = $cli->eventfd;
    ok $cefd >= 0, 'client eventfd (reply) created';
    is $cli->fileno, $cefd, 'client fileno matches';
}

# eventfd notification round-trip via fork
{
    my $epath = tmpnam();
    my $esrv = Data::ReqRep::Shared->new($epath, 8, 4, 256);
    my $req_efd = $esrv->eventfd;      # request notification fd
    my $rep_efd = $esrv->reply_eventfd; # reply notification fd

    my $pid = fork();
    if ($pid == 0) {
        # child = server: inherited fds via fork
        # Use recv_wait (futex) then signal reply via handle
        my ($rq, $ri) = $esrv->recv_wait(2.0);
        if (defined $rq) {
            $esrv->reply($ri, "efd:$rq");
            $esrv->reply_notify;  # signal reply eventfd
        }
        exit 0;
    }

    # parent = client: share fds via fork inheritance
    my $ecli = Data::ReqRep::Shared::Client->new($epath);
    $ecli->req_eventfd_set($req_efd);  # set request notification fd
    $ecli->eventfd_set($rep_efd);      # set reply notification fd

    my $eid = $ecli->send("efd_test");
    ok defined $eid, 'eventfd test: send ok';
    $ecli->notify;  # signal server via req eventfd

    # wait for reply via select on the reply eventfd
    my $rin = '';
    vec($rin, $rep_efd, 1) = 1;
    my $ready = select($rin, undef, undef, 2.0);
    ok $ready, 'eventfd test: reply eventfd fired';
    $ecli->eventfd_consume;

    my $eresp = $ecli->get($eid);
    is $eresp, 'efd:efd_test', 'eventfd test: round-trip ok';

    waitpid $pid, 0;
    $esrv->unlink;
}

# Arena wraparound: fill arena, consume, refill
{
    my $apath = tmpnam();
    # small arena (4096) with small queue
    my $asrv = Data::ReqRep::Shared->new($apath, 4, 4, 256, 4096);
    my $acli = Data::ReqRep::Shared::Client->new($apath);

    my $big = "x" x 500;
    for my $round (1..3) {
        # Fill queue with big messages to consume arena
        for my $i (1..4) {
            my $aid = $acli->send_wait($big, 0.5);
            ok defined $aid, "arena round $round msg $i: send ok";
            my ($arq, $ari) = $asrv->recv;
            is length($arq), 500, "arena round $round msg $i: recv ok";
            $asrv->reply($ari, "ok");
            $acli->get($aid);
        }
    }

    $asrv->unlink;
}

# memfd
{
    my $msrv = Data::ReqRep::Shared->new_memfd("test_rr", 8, 4, 256);
    ok $msrv, 'memfd channel created';
    my $mfd = $msrv->memfd;
    ok $mfd >= 0, 'memfd returns fd';

    my $msrv2 = Data::ReqRep::Shared->new_from_fd($mfd);
    ok $msrv2, 'new_from_fd works';
}

# Cleanup
$srv->unlink;
ok !-e $path, 'backing file removed';

done_testing;
