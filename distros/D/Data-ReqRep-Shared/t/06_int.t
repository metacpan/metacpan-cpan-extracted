use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $path = tmpnam();

# Create / open
my $srv = Data::ReqRep::Shared::Int->new($path, 64, 16);
ok $srv, 'int server created';
is $srv->capacity, 64, 'capacity';
is $srv->resp_slots, 16, 'resp_slots';

my $cli = Data::ReqRep::Shared::Int::Client->new($path);
ok $cli, 'int client created';

# Basic round-trip
my $id = $cli->send(42);
ok defined $id, 'int send';
my ($val, $rid) = $srv->recv;
is $val, 42, 'int recv value';
is $rid, $id, 'int recv id matches';
$srv->reply($rid, 99);
my $resp = $cli->get($id);
is $resp, 99, 'int get response';

# Negative values
{
    my $id2 = $cli->send(-12345);
    my ($v, $ri) = $srv->recv;
    is $v, -12345, 'negative request';
    $srv->reply($ri, -99999);
    is $cli->get($id2), -99999, 'negative response';
}

# Multiple concurrent
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

# Cancel
{
    my $cid = $cli->send(777);
    $cli->cancel($cid);
    my ($v, $ri) = $srv->recv;
    my $ok = $srv->reply($ri, 0);
    ok !$ok, 'int: reply to cancelled slot fails';
}

# Blocking
{
    my $id3 = $cli->send_wait(55, 1.0);
    ok defined $id3, 'int send_wait';
    my ($v, $ri) = $srv->recv_wait(1.0);
    is $v, 55, 'int recv_wait';
    $srv->reply($ri, 66);
    is $cli->get_wait($id3, 1.0), 66, 'int get_wait';
}

# req (sync)
{
    my $pid = fork();
    if ($pid == 0) {
        my $s = Data::ReqRep::Shared::Int->new($path, 64, 16);
        for (1..5) {
            my ($v, $ri) = $s->recv_wait(2.0);
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

# req_wait with timeout
{
    my $r = $cli->req_wait(1, 0.01);
    ok !defined $r, 'int req_wait timeout';
    $srv->recv;  # drain
}

# is_empty, stats, pending
{
    ok $srv->is_empty, 'int is_empty';
    my $s = $srv->stats;
    ok $s->{requests} > 0, 'int stats: requests > 0';
    ok $s->{replies} > 0, 'int stats: replies > 0';
    is $cli->pending, 0, 'int pending: 0';
    is $cli->capacity, 64, 'int client capacity';
    ok $cli->is_empty, 'int client is_empty';
}

# ABA — generation prevents reply to recycled slot
{
    my $ap = tmpnam();
    my $as = Data::ReqRep::Shared::Int->new($ap, 8, 1);  # 1 slot
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

# Slot exhaustion
{
    my $sp = tmpnam();
    my $ss = Data::ReqRep::Shared::Int->new($sp, 32, 2);  # 2 slots
    my $sc = Data::ReqRep::Shared::Int::Client->new($sp);

    my $s1 = $sc->send(1);
    my $s2 = $sc->send(2);
    ok defined $s1 && defined $s2, 'int slot exhaustion: 2 sends ok';
    my $s3 = $sc->send(3);
    ok !defined $s3, 'int slot exhaustion: 3rd send fails';

    # free a slot
    my ($v, $ri) = $ss->recv;
    $ss->reply($ri, $v);
    $sc->get($s1);
    $s3 = $sc->send(3);
    ok defined $s3, 'int slot exhaustion: send ok after freeing';

    # cleanup
    ($v, $ri) = $ss->recv; $ss->reply($ri, $v); $sc->get($s2);
    ($v, $ri) = $ss->recv; $ss->reply($ri, $v); $sc->get($s3);
    $ss->unlink;
}

# Queue full
{
    my $qp = tmpnam();
    my $qs = Data::ReqRep::Shared::Int->new($qp, 2, 8);  # cap=2
    my $qc = Data::ReqRep::Shared::Int::Client->new($qp);

    my $q1 = $qc->send(10);
    my $q2 = $qc->send(20);
    ok defined $q1 && defined $q2, 'int queue full: 2 sends ok';
    my $q3 = $qc->send(30);
    ok !defined $q3, 'int queue full: 3rd send fails (queue full)';

    # cleanup
    for ($q1, $q2) {
        my ($v, $ri) = $qs->recv;
        $qs->reply($ri, $v);
        $qc->get($_);
    }
    $qs->unlink;
}

# clear releases slots
{
    my $cp = tmpnam();
    my $cs = Data::ReqRep::Shared::Int->new($cp, 16, 4);
    my $cc = Data::ReqRep::Shared::Int::Client->new($cp);

    $cc->send(1); $cc->send(2);
    is $cc->pending, 2, 'int clear: 2 pending';
    $cs->clear;
    is $cs->size, 0, 'int clear: queue empty';
    is $cc->pending, 0, 'int clear: slots released';

    # new request works
    my $cid = $cc->send(99);
    ok defined $cid, 'int clear: send after clear ok';
    my ($cv, $cri) = $cs->recv;
    is $cv, 99, 'int clear: recv after clear';
    $cs->reply($cri, 88);
    is $cc->get($cid), 88, 'int clear: round-trip ok';

    $cs->unlink;
}

# Boundary values
{
    for my $val (0, -1, 2147483647, -2147483648) {
        my $id = $cli->send($val);
        my ($v, $ri) = $srv->recv;
        is $v, $val, "int boundary: $val round-trip";
        $srv->reply($ri, $val);
        is $cli->get($id), $val, "int boundary: $val response";
    }
}

# memfd
{
    my $ms = Data::ReqRep::Shared::Int->new_memfd("int_test", 16, 4);
    ok $ms, 'int memfd created';
    my $mfd = $ms->memfd;
    my $ms2 = Data::ReqRep::Shared::Int->new_from_fd($mfd);
    ok $ms2, 'int new_from_fd';

    # Int::Client new_from_fd
    my $mc = Data::ReqRep::Shared::Int::Client->new_from_fd($mfd);
    ok $mc, 'int client new_from_fd';
}

# eventfd
{
    my $efd = $srv->eventfd;
    ok $efd >= 0, 'int eventfd created';
    is $srv->fileno, $efd, 'int fileno';
    my $rfd = $srv->reply_eventfd;
    ok $rfd >= 0, 'int reply_eventfd';

    my $cefd = $cli->eventfd;
    ok $cefd >= 0, 'int client eventfd';
}

$srv->unlink;
done_testing;
