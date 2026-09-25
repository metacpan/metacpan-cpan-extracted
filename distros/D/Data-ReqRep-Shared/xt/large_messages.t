use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

{
    my $path = tmpnam();
    my $resp_max = 4096;
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, $resp_max);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $big_resp = "R" x $resp_max;
    my $id = $cli->send("req");
    my ($rq, $ri) = $srv->recv;
    my $ok = $srv->reply($ri, $big_resp);
    ok $ok, "reply at exact resp_data_max ($resp_max bytes)";
    my $resp = $cli->get($id);
    is length($resp), $resp_max, 'got full-size response';
    is $resp, $big_resp, 'response data matches';

    $id = $cli->send("req2");
    ($rq, $ri) = $srv->recv;
    eval { $srv->reply($ri, "X" x ($resp_max + 1)) };
    like $@, qr/response too long/, 'reply over resp_data_max croaks';
    # slot is still acquired — reply failed
    $cli->cancel($id);

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $arena = 16384;
    my $srv = Data::ReqRep::Shared->new($path, 16, 8, 64, $arena);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $huge = "A" x ($arena - 64);  # leave room for alignment
    my $id = $cli->send($huge);
    ok defined $id, 'large request near arena size: send ok';
    my ($rq, $ri) = $srv->recv;
    is length($rq), length($huge), 'large request recv ok';
    is $rq, $huge, 'large request data matches';
    $srv->reply($ri, "ok");
    $cli->get($id);

    my $medium = "B" x 2000;
    my @ids;
    my $sent = 0;
    for (1..16) {
        my $mid = $cli->send($medium);
        if (defined $mid) {
            push @ids, $mid;
            $sent++;
        } else {
            last;
        }
    }
    ok $sent >= 1, "medium messages: sent $sent before arena/queue full";

    for my $mid (@ids) {
        my ($r, $ri2) = $srv->recv;
        is length($r), length($medium), 'medium msg data intact';
        $srv->reply($ri2, "ok");
        $cli->get($mid);
    }

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4, 2, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $big = "C" x 3000;
    my $id = $cli->send($big);
    ok defined $id, 'large request (3KB): send ok';
    my ($r, $ri) = $srv->recv;
    is length($r), 3000, 'large request: recv length ok';
    $srv->reply($ri, "ok");
    $cli->get($id);

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 1024);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id = $cli->send("need_ack");
    my ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "");
    my $resp = $cli->get($id);
    is $resp, '', 'zero-length response';
    is length($resp), 0, 'zero-length response length';

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 0);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id = $cli->send("fire_and_ack");
    my ($rq, $ri) = $srv->recv;
    is $rq, 'fire_and_ack', 'ack-only: recv ok';
    $srv->reply($ri, "");
    my $resp = $cli->get($id);
    is $resp, '', 'ack-only: empty response ok';

    $id = $cli->send("try_data");
    ($rq, $ri) = $srv->recv;
    eval { $srv->reply($ri, "x") };
    like $@, qr/response too long/, 'ack-only: non-empty reply croaks';
    $cli->cancel($id);

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $arena = 8192;
    my $srv = Data::ReqRep::Shared->new($path, 8, 8, 64, $arena);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $msg = "W" x 2000;
    for my $round (1..10) {
        my $id = $cli->send_wait($msg, 1.0);
        ok defined $id, "arena wrap round $round: send ok";
        my ($r, $ri) = $srv->recv;
        is length($r), 2000, "arena wrap round $round: data intact";
        $srv->reply($ri, "ok");
        $cli->get($id);
    }

    my $stats = $srv->stats;
    is $stats->{requests}, 10, 'arena wrap: all 10 requests processed';

    $srv->unlink;
}

done_testing;
