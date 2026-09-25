use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $path = tmpnam();

my $srv = Data::ReqRep::Shared::Int->new($path, 64, 16);
ok $srv, 'int server created';
is $srv->capacity, 64, 'capacity';
is $srv->resp_slots, 16, 'resp_slots';

my $cli = Data::ReqRep::Shared::Int::Client->new($path);
ok $cli, 'int client created';

my $id = $cli->send(42);
ok defined $id, 'int send';
my ($val, $rid) = $srv->recv;
is $val, 42, 'int recv value';
is $rid, $id, 'int recv id matches';
$srv->reply($rid, 99);
my $resp = $cli->get($id);
is $resp, 99, 'int get response';

{
    my $id2 = $cli->send(-12345);
    my ($v, $ri) = $srv->recv;
    is $v, -12345, 'negative request';
    $srv->reply($ri, -99999);
    is $cli->get($id2), -99999, 'negative response';
}

{
    my @ids = map { $cli->send($_) } (100..104);
    is $srv->size, 5, '5 pending int requests';
    my @reqs;
    while (my ($v, $ri) = $srv->recv) {
        push @reqs, [$v, $ri];
    }
    is scalar @reqs, 5, 'recv all 5';
    for my $i (0..4) {
        $srv->reply($reqs[$i][1], $reqs[$i][0] * 10);
    }
    for my $i (0..4) {
        is $cli->get($ids[$i]), (100 + $i) * 10, "int response $i";
    }
}

{
    my $cid = $cli->send(777);
    $cli->cancel($cid);
    my ($v, $ri) = $srv->recv;
    my $ok = $srv->reply($ri, 0);
    ok !$ok, 'int: reply to cancelled slot fails';
}

{
    my $id3 = $cli->send_wait(55, 1.0);
    ok defined $id3, 'int send_wait';
    my ($v, $ri) = $srv->recv_wait(1.0);
    is $v, 55, 'int recv_wait';
    $srv->reply($ri, 66);
    is $cli->get_wait($id3, 1.0), 66, 'int get_wait';
}

{
    my $pid = fork();
    if ($pid == 0) {
        my $s = Data::ReqRep::Shared::Int->new($path, 64, 16);
        for (1..5) {
            my ($v, $ri) = $s->recv_wait(30);
            last unless defined $v;
            $s->reply($ri, $v * 2);
        }
        exit 0;
    }
    my $c = Data::ReqRep::Shared::Int::Client->new($path);
    for my $i (1..5) {
        is $c->req($i), $i * 2, "int req() $i";
    }
    waitpid $pid, 0;
}

{
    my $r = $cli->req_wait(1, 0.01);
    ok !defined $r, 'int req_wait timeout';
    $srv->recv;
}

{
    ok $srv->is_empty, 'int is_empty';
    my $s = $srv->stats;
    ok $s->{requests} > 0, 'int stats: requests > 0';
    ok $s->{replies} > 0, 'int stats: replies > 0';
    is $cli->pending, 0, 'int pending: 0';
    is $cli->capacity, 64, 'int client capacity';
    ok $cli->is_empty, 'int client is_empty';
}

{
    my $s = Data::ReqRep::Shared::Int->new_memfd('stats', 2, 4);
    my $c = Data::ReqRep::Shared::Int::Client->new_from_fd($s->memfd);
    $c->send($_) for 1, 2;
    ok !defined $c->send(3), 'int stats: a send finds the queue full';
    is $c->pending, 2, '  and holds no slot after';
    my ($v, $i) = $s->recv;
    $s->reply($i, $v);
    $s->recv;
    ok !(my @none = $s->recv), 'int stats: a recv finds the queue empty';
    my $st = $s->stats;
    is $st->{requests}, 2, 'int stats: requests';
    is $st->{replies}, 1, 'int stats: replies';
    cmp_ok $st->{send_full}, '>=', 1, 'int stats: send_full';
    cmp_ok $st->{recv_empty}, '>=', 1, 'int stats: recv_empty';
    is $st->{recoveries}, 0, 'int stats: recoveries';
}

{
    my $ap = tmpnam();
    my $as = Data::ReqRep::Shared::Int->new($ap, 8, 1);
    my $ac = Data::ReqRep::Shared::Int::Client->new($ap);

    my $id1 = $ac->send(100);
    ok defined $id1, 'int ABA: first send';
    $ac->cancel($id1);
    my $id2 = $ac->send(200);
    ok defined $id2, 'int ABA: second send (same slot, new gen)';
    isnt $id1, $id2, 'int ABA: different ids';

    my ($v1, $ri1) = $as->recv;
    my $ok1 = $as->reply($ri1, 999);
    ok !$ok1, 'int ABA: reply with stale gen fails';

    my ($v2, $ri2) = $as->recv;
    $as->reply($ri2, 777);
    is $ac->get($id2), 777, 'int ABA: correct reply to new gen';

    $as->unlink;
}

{
    my $sp = tmpnam();
    my $ss = Data::ReqRep::Shared::Int->new($sp, 32, 2);
    my $sc = Data::ReqRep::Shared::Int::Client->new($sp);

    my $s1 = $sc->send(1);
    my $s2 = $sc->send(2);
    ok defined $s1 && defined $s2, 'int slot exhaustion: 2 sends ok';
    my $s3 = $sc->send(3);
    ok !defined $s3, 'int slot exhaustion: 3rd send fails';

    my ($v, $ri) = $ss->recv;
    $ss->reply($ri, $v);
    $sc->get($s1);
    $s3 = $sc->send(3);
    ok defined $s3, 'int slot exhaustion: send ok after freeing';

    ($v, $ri) = $ss->recv; $ss->reply($ri, $v); $sc->get($s2);
    ($v, $ri) = $ss->recv; $ss->reply($ri, $v); $sc->get($s3);
    $ss->unlink;
}

{
    my $qp = tmpnam();
    my $qs = Data::ReqRep::Shared::Int->new($qp, 2, 8);
    my $qc = Data::ReqRep::Shared::Int::Client->new($qp);

    my $q1 = $qc->send(10);
    my $q2 = $qc->send(20);
    ok defined $q1 && defined $q2, 'int queue full: 2 sends ok';
    my $q3 = $qc->send(30);
    ok !defined $q3, 'int queue full: 3rd send fails (queue full)';

    for ($q1, $q2) {
        my ($v, $ri) = $qs->recv;
        $qs->reply($ri, $v);
        $qc->get($_);
    }
    $qs->unlink;
}

{
    my $cp = tmpnam();
    my $cs = Data::ReqRep::Shared::Int->new($cp, 16, 4);
    my $cc = Data::ReqRep::Shared::Int::Client->new($cp);

    $cc->send(1); $cc->send(2);
    is $cc->pending, 2, 'int clear: 2 pending';
    $cs->clear;
    is $cs->size, 0, 'int clear: queue empty';
    is $cc->pending, 0, 'int clear: slots released';

    my $cid = $cc->send(99);
    ok defined $cid, 'int clear: send after clear ok';
    my ($cv, $cri) = $cs->recv;
    is $cv, 99, 'int clear: recv after clear';
    $cs->reply($cri, 88);
    is $cc->get($cid), 88, 'int clear: round-trip ok';

    $cs->unlink;
}

{
    for my $val (0, -1, 2147483647, -2147483648) {
        my $id = $cli->send($val);
        my ($v, $ri) = $srv->recv;
        is $v, $val, "int boundary: $val round-trip";
        $srv->reply($ri, $val);
        is $cli->get($id), $val, "int boundary: $val response";
    }
}

{
    my $ms = Data::ReqRep::Shared::Int->new_memfd("int_test", 16, 4);
    ok $ms, 'int memfd created';
    my $mfd = $ms->memfd;
    my $ms2 = Data::ReqRep::Shared::Int->new_from_fd($mfd);
    ok $ms2, 'int new_from_fd';

    my $mc = Data::ReqRep::Shared::Int::Client->new_from_fd($mfd);
    ok $mc, 'int client new_from_fd';
}

{
    my $efd = $srv->eventfd;
    ok $efd >= 0, 'int eventfd created';
    is $srv->fileno, $efd, 'int fileno';
    my $rfd = $srv->reply_eventfd;
    ok $rfd >= 0, 'int reply_eventfd';

    my $cefd = $cli->eventfd;
    ok $cefd >= 0, 'int client eventfd';
}

{
    my $p = tmpnam();
    my $s = Data::ReqRep::Shared::Int->new($p, 16, 4);
    my $c = Data::ReqRep::Shared::Int::Client->new($p);
    is $s->fileno, -1, 'no request eventfd yet';
    is $s->reply_fileno, -1, '  nor a reply one';
    is $c->fileno, -1, '  nor on the client';
    is $c->req_fileno, -1, '  either way';
    is $s->eventfd_consume, undef, 'consume without an eventfd gives undef';
    is $s->reply_eventfd_consume, undef, '  for replies too';
    is $c->eventfd_consume, undef, '  and on the client';
    ok eval { $c->notify; $s->notify; $s->reply_notify; 1 }, 'notify without an eventfd does nothing';

    my $req_fd = $s->eventfd;
    my $rep_fd = $s->reply_eventfd;
    is $s->fileno, $req_fd, 'fileno is the request eventfd';
    is $s->reply_fileno, $rep_fd, 'reply_fileno is the reply eventfd';
    $c->req_eventfd_set($req_fd);
    $c->eventfd_set($rep_fd);
    ok $c->req_fileno >= 0 && $c->req_fileno != $req_fd, 'req_eventfd_set keeps a duplicate';
    ok $c->fileno >= 0 && $c->fileno != $rep_fd, 'eventfd_set keeps a duplicate';

    $c->notify for 1 .. 2;
    my $id = $c->send(7);
    is $s->eventfd_consume, 2, 'the server sees both client notifications';
    is $s->eventfd_consume, undef, '  and nothing after';
    my ($v, $rid) = $s->recv;
    is $v, 7, 'the request arrives';
    ok $s->reply($rid, 8), 'reply';
    $s->reply_notify for 1 .. 3;
    is $c->eventfd_consume, 3, 'the client sees the three reply notifications';
    is $c->get($id), 8, '  and gets the reply';

    my $cfd = $c->eventfd;
    is $c->fileno, $cfd, 'a client eventfd of its own replaces the set one';
    $s->eventfd_set($c->req_fileno);
    $s->reply_eventfd_set($cfd);
    $c->notify;
    is $s->eventfd_consume, 1, 'eventfd_set on the server takes the client request eventfd';
    $s->reply_notify;
    is $c->eventfd_consume, 1, 'reply_eventfd_set takes the client reply eventfd';

    ok !eval { $s->eventfd_set(99999); 1 }, 'eventfd_set croaks on a closed descriptor';
    like $@, qr/Int->eventfd_set: \S/, '  with the reason';
    ok !eval { $c->req_eventfd_set(0); 1 }, 'req_eventfd_set croaks on a descriptor that is not an eventfd';
    like $@, qr/fd 0 is not an eventfd/, '  with the reason';
    $s->unlink;
}

$srv->unlink;
done_testing;
