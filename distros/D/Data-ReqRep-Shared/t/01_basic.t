use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tmpnam();

my $srv = Data::ReqRep::Shared->new($path, 16, 8, 1024);
ok $srv, 'server created';
is $srv->capacity, 16, 'capacity';
is $srv->resp_slots, 8, 'resp_slots';
is $srv->resp_size, 1024, 'resp_size';
is $srv->size, 0, 'empty queue';
ok $srv->is_empty, 'is_empty';

my $cli = Data::ReqRep::Shared::Client->new($path);
ok $cli, 'client created';
is $cli->resp_slots, 8, 'client sees resp_slots';
is $cli->capacity, 16, 'client sees capacity';
ok $cli->is_empty, 'client sees is_empty';

my @r = $srv->recv;
is scalar @r, 0, 'recv on empty returns empty list';

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

{
    my $id3 = $cli->send("");
    my ($req3, $rid3) = $srv->recv;
    is $req3, '', 'empty request';
    $srv->reply($rid3, "");
    my $resp3 = $cli->get($id3);
    is $resp3, '', 'empty response';
}

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

{
    # Use 1 resp_slot to force same-slot reuse
    my $aba_path = tmpnam();
    my $aba_srv = Data::ReqRep::Shared->new($aba_path, 8, 1, 256);
    my $aba_cli = Data::ReqRep::Shared::Client->new($aba_path);

    my $id1 = $aba_cli->send("first");
    ok defined $id1, 'ABA: first send ok';

    $aba_cli->cancel($id1);

    my $id2 = $aba_cli->send("second");
    ok defined $id2, 'ABA: second send ok';
    isnt $id1, $id2, 'ABA: different ids (same slot, different generation)';
    $aba_cli->cancel($id1);

    my ($rq1, $ri1) = $aba_srv->recv;
    is $rq1, 'first', 'ABA: recv first';

    my $ok = $aba_srv->reply($ri1, "wrong_reply");
    ok !$ok, 'ABA: reply with stale generation fails';

    my ($rq2, $ri2) = $aba_srv->recv;
    is $rq2, 'second', 'ABA: recv second';
    $aba_srv->reply($ri2, "correct_reply");
    is $aba_cli->get($id1), undef, 'ABA: get with the stale id takes nothing';
    $aba_cli->cancel($id1);

    my $resp = $aba_cli->get($id2);
    is $resp, 'correct_reply', 'ABA: correct response for second request';

    $aba_srv->unlink;
}

{
    my $lc_id = $cli->send("late_cancel");
    ok defined $lc_id, 'late_cancel: send ok';
    my ($lc_rq, $lc_ri) = $srv->recv;
    is $lc_rq, 'late_cancel', 'late_cancel: server received';
    $srv->reply($lc_ri, "late_reply");
    $cli->cancel($lc_id);
    my $lc_resp = $cli->get($lc_id);
    is $lc_resp, undef, 'late_cancel: cancel drops a reply that already arrived';
}

{
    my $cw_path = tmpnam();
    my $cw_srv = Data::ReqRep::Shared->new($cw_path, 8, 4, 256);
    my $cw_cli = Data::ReqRep::Shared::Client->new($cw_path);

    my $cw_id = $cw_cli->send("cancel_wait");
    ok defined $cw_id, 'cancel_wait: send ok';

    my $pid = fork();
    if ($pid == 0) {
        select(undef, undef, undef, 0.1);
        $cw_cli->cancel($cw_id);
        exit 0;
    }

    my $cw_resp = $cw_cli->get_wait($cw_id, 2.0);
    ok !defined $cw_resp, 'cancel_wait: get_wait returns undef after cancel';

    waitpid $pid, 0;
    $cw_srv->recv;
    $cw_srv->unlink;
}

{
    my @empty = $srv->recv_wait(0.01);
    is scalar @empty, 0, 'recv_wait times out on empty queue';
}

{
    my $id4 = $cli->send_wait("blocking_req", 1.0);
    ok defined $id4, 'send_wait returns id';
    my ($rq4, $ri4) = $srv->recv_wait(1.0);
    is $rq4, 'blocking_req', 'recv_wait got data';
    $srv->reply($ri4, "blocking_resp");
    my $rsp4 = $cli->get_wait($id4, 1.0);
    is $rsp4, 'blocking_resp', 'get_wait got response';
}

{
    my $pid = fork();
    if ($pid == 0) {
        my $child_srv = Data::ReqRep::Shared->new($path, 16, 8, 1024);
        for (1..3) {
            my ($rq, $ri) = $child_srv->recv_wait(30);
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

{
    my $p = tmpnam();
    my $s = Data::ReqRep::Shared->new($p, 2, 4, 64);
    my $c = Data::ReqRep::Shared::Client->new($p);
    $c->send("s$_") for 1, 2;
    ok !defined $c->send('s3'), 'stats: a send finds the queue full';
    is $c->pending, 2, '  and holds no slot after';
    my ($r, $i) = $s->recv;
    $s->reply($i, $r);
    $s->recv;
    ok !(my @none = $s->recv), 'stats: a recv finds the queue empty';
    my $st = $s->stats;
    is $st->{requests}, 2, 'stats: requests';
    is $st->{replies}, 1, 'stats: replies';
    cmp_ok $st->{send_full}, '>=', 1, 'stats: send_full';
    cmp_ok $st->{recv_empty}, '>=', 1, 'stats: recv_empty';
    is $st->{recoveries}, 0, 'stats: recoveries';
    $s->unlink;
}

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

{
    my $epath = tmpnam();
    my $esrv = Data::ReqRep::Shared->new($epath, 8, 4, 256);
    my $req_efd = $esrv->eventfd;
    my $rep_efd = $esrv->reply_eventfd;

    my $pid = fork();
    if ($pid == 0) {
        my ($rq, $ri) = $esrv->recv_wait(30);
        if (defined $rq) {
            $esrv->reply($ri, "efd:$rq");
            $esrv->reply_notify;
        }
        exit 0;
    }

    my $ecli = Data::ReqRep::Shared::Client->new($epath);
    $ecli->req_eventfd_set($req_efd);
    $ecli->eventfd_set($rep_efd);
    # The handle keeps its own duplicate: $req_efd stays owned by $esrv, which
    # would otherwise be closed twice when both handles are destroyed.
    ok $ecli->req_fileno >= 0 && $ecli->req_fileno != $req_efd,
        'client holds its own duplicate of the set fd';

    my $eid = $ecli->send("efd_test");
    ok defined $eid, 'eventfd test: send ok';
    $ecli->notify;

    my $rin = '';
    vec($rin, $rep_efd, 1) = 1;
    my $ready = select($rin, undef, undef, 10);
    ok $ready, 'eventfd test: reply eventfd fired';
    $ecli->eventfd_consume;

    my $eresp = $ecli->get($eid);
    is $eresp, 'efd:efd_test', 'eventfd test: round-trip ok';

    waitpid $pid, 0;
    $esrv->unlink;
}

{
    my $rsrv = Data::ReqRep::Shared->new(undef, 8, 4, 256);
    my $rfd = $rsrv->reply_eventfd;
    ok $rfd >= 0, 'reply_eventfd';
    $rsrv->reply_notify for 1..3;
    my $count = $rsrv->reply_eventfd_consume;
    is $count, 3, 'reply_eventfd_consume returns accumulated count';
}

# Arena wraparound
{
    my $apath = tmpnam();
    my $asrv = Data::ReqRep::Shared->new($apath, 4, 4, 256, 4096);
    my $acli = Data::ReqRep::Shared::Client->new($apath);

    my $big = "x" x 500;
    for my $round (1..3) {
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

{
    my $msrv = Data::ReqRep::Shared->new_memfd("test_rr", 8, 4, 256);
    ok $msrv, 'memfd channel created';
    my $mfd = $msrv->memfd;
    ok $mfd >= 0, 'memfd returns fd';

    my $msrv2 = Data::ReqRep::Shared->new_from_fd($mfd);
    ok $msrv2, 'new_from_fd works';
}

$srv->unlink;
ok !-e $path, 'backing file removed';

done_testing;
