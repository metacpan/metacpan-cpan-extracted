use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 64, 16, 1024);
my $cli = Data::ReqRep::Shared::Client->new($path);

{
    my @ids;
    push @ids, $cli->send("msg$_") for 1..5;
    is $srv->size, 5, 'recv_multi: 5 pending';

    my @items = $srv->recv_multi(3);
    is scalar @items, 6, 'recv_multi(3): 6 elements (3 pairs)';
    is $items[0], 'msg1', 'recv_multi: first data';
    is $items[2], 'msg2', 'recv_multi: second data';
    is $items[4], 'msg3', 'recv_multi: third data';
    is $srv->size, 2, 'recv_multi: 2 remaining';

    for (0..2) {
        $srv->reply($items[$_ * 2 + 1], "re:$items[$_ * 2]");
    }
    is $cli->get($ids[0]), 're:msg1', 'recv_multi: reply 1 ok';
    is $cli->get($ids[1]), 're:msg2', 'recv_multi: reply 2 ok';
    is $cli->get($ids[2]), 're:msg3', 'recv_multi: reply 3 ok';

    my @rest = $srv->recv_multi(10);
    is scalar @rest, 4, 'recv_multi: drained 2 remaining';
    $srv->reply($rest[1], "ok");
    $srv->reply($rest[3], "ok");
    $cli->get($ids[3]);
    $cli->get($ids[4]);
}

{
    my @empty = $srv->recv_multi(10);
    is scalar @empty, 0, 'recv_multi on empty: empty list';
}

{
    my $pid = fork();
    if ($pid == 0) {
        select(undef, undef, undef, 0.05);
        my $child_cli = Data::ReqRep::Shared::Client->new($path);
        $child_cli->send("batch$_") for 1..4;
        require POSIX;
        POSIX::_exit(0);
    }

    my @items = $srv->recv_wait_multi(10, 30.0);
    ok scalar @items >= 2, 'recv_wait_multi: got at least 1 pair';
    ok scalar @items <= 8, 'recv_wait_multi: got at most 4 pairs';

    my ($pairs, $accepted) = (@items / 2, 0);
    while (@items) {
        my ($data, $id) = splice @items, 0, 2;
        $accepted++ if $srv->reply($id, "ok");
    }
    is $accepted, $pairs, 'recv_wait_multi: every request received can be replied to';
    waitpid $pid, 0;
    while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
}

{
    my $t0 = time;
    my @empty = $srv->recv_wait_multi(10, 0.01);
    is scalar @empty, 0, 'recv_wait_multi timeout: empty list';
    cmp_ok time - $t0, '<', 30, 'recv_wait_multi returned (not hung)';
}

{
    my @ids;
    push @ids, $cli->send("d$_") for 1..6;

    my @all = $srv->drain;
    is scalar @all, 12, 'drain: got 6 pairs (12 elements)';
    is $all[0], 'd1', 'drain: first';
    is $all[10], 'd6', 'drain: last';

    for my $i (0..5) {
        $srv->reply($all[$i * 2 + 1], "ok");
        $cli->get($ids[$i]);
    }
}

{
    my @ids_m;
    push @ids_m, $cli->send("m$_") for 1..5;
    my @partial = $srv->drain(3);
    is scalar @partial, 6, 'drain(3): got 3 pairs';
    is $srv->size, 2, 'drain(3): 2 remaining';

    while (@partial) {
        my (undef, $id) = splice @partial, 0, 2;
        $srv->reply($id, "ok");
    }
    while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
    is scalar(grep { ($cli->get($_) // '') eq 'ok' } @ids_m), 5, 'drain(3): every request drained or received gets its reply';
}

{
    my $np = tmpnam();
    my $nsrv = Data::ReqRep::Shared->new($np, 16, 8, 256);
    my $ncli = Data::ReqRep::Shared::Client->new($np);
    my $efd = $nsrv->eventfd;
    $ncli->req_eventfd_set($efd);

    my $id1 = $ncli->send_notify("sn1");
    ok defined $id1, 'send_notify: returns id';

    my $rin = '';
    vec($rin, $efd, 1) = 1;
    my $ready = select($rin, undef, undef, 1.0);
    ok $ready, 'send_notify: eventfd is readable';
    $nsrv->eventfd_consume;

    my ($r1, $ri1) = $nsrv->recv;
    is $r1, 'sn1', 'send_notify: recv ok';
    $nsrv->reply($ri1, "ok");
    $ncli->get($id1);

    my $id2 = $ncli->send_wait_notify("swn1", 1.0);
    ok defined $id2, 'send_wait_notify: returns id';
    $rin = '';
    vec($rin, $efd, 1) = 1;
    $ready = select($rin, undef, undef, 1.0);
    ok $ready, 'send_wait_notify: eventfd is readable';
    $nsrv->eventfd_consume;
    my ($r2, $ri2) = $nsrv->recv;
    $nsrv->reply($ri2, "ok");
    $ncli->get($id2);

    $nsrv->unlink;
}

{
    my $pp = tmpnam();
    my $ps = Data::ReqRep::Shared->new($pp, 16, 8, 256);
    my $pc = Data::ReqRep::Shared::Client->new($pp);

    is $pc->pending, 0, 'pending: 0 initially';
    my $id1 = $pc->send("p1");
    my $id2 = $pc->send("p2");
    is $pc->pending, 2, 'pending: 2 after sends';
    my ($r, $ri) = $ps->recv;
    $ps->reply($ri, "ok");
    is $pc->pending, 2, 'pending: a reply not yet read still counts';
    $pc->get($id1);
    is $pc->pending, 1, 'pending: 1 after get';
    ($r, $ri) = $ps->recv;
    $ps->reply($ri, "ok");
    $pc->get($id2);
    is $pc->pending, 0, 'pending: 0 after all get';

    $ps->unlink;
}

{
    my $pp = tmpnam();
    my $ps = Data::ReqRep::Shared->new($pp, 16, 8, 256);
    pipe my $sent_r, my $sent_w or die "pipe: $!";
    pipe my $done_r, my $done_w or die "pipe: $!";
    my $pid = fork() // die "fork: $!";
    if ($pid == 0) {
        close $sent_r; close $done_w;
        my $oc = Data::ReqRep::Shared::Client->new($pp);
        $oc->send("other$_") for 1, 2;
        syswrite $sent_w, "1";
        sysread $done_r, my $go, 1;
        exit 0;
    }
    close $sent_w; close $done_r;
    is sysread($sent_r, my $sent, 1), 1, 'pending: the other client sent';
    my $pc = Data::ReqRep::Shared::Client->new($pp);
    is $pc->pending, 0, "pending: another process's queued requests are not counted";
    my (undef, $rid) = $ps->recv;
    is $pc->pending, 0, 'pending: nor one this process received for it';
    $ps->reply($rid, "r");
    is $pc->pending, 0, 'pending: nor its reply not yet read';
    $pc->send("mine");
    is $pc->pending, 1, "pending: this process's own request is";
    syswrite $done_w, "1";
    waitpid $pid, 0;
    is $?, 0, 'pending: the other client exited cleanly';
    $ps->unlink;
}

{
    my $ap = tmpnam();
    my $as = Data::ReqRep::Shared->new($ap, 16, 8, 16, 4096);
    my $ac = Data::ReqRep::Shared::Client->new($ap);
    my @queued;
    my $send = sub { push @queued, $_[0] if defined $ac->send($_[0]) };
    $send->($_) for 'a' x 2000, 'b' x 2000;
    is +($as->recv)[0], shift @queued, 'arena wrap: first request intact';
    $send->($_) for 'c' x 1000, 'd' x 1000, 'e' x 8;
    ok grep($_ eq 'c' x 1000, @queued), 'arena wrap: a send wrapped';
    my @got;
    while (my ($r) = $as->recv) { push @got, $r }
    ok @got == @queued && !grep($got[$_] ne $queued[$_], 0 .. $#got), 'arena wrap: every queued request arrives intact';
    $as->unlink;
}

{
    my $ap = tmpnam();
    my $as = Data::ReqRep::Shared->new($ap, 16, 32, 16, 4096);
    my $ac = Data::ReqRep::Shared::Client->new($ap);
    my $n = defined $ac->send('p' x 1000) ? 1 : 0;
    for (1 .. 20) { $n++ if defined $ac->send('p' x 1000); $as->recv }
    is $n, 21, 'arena: a queue one request deep never runs out of room';
    $as->unlink;
}

$srv->unlink;
done_testing;
