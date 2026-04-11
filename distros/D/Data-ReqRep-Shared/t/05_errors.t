use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

# Response too long
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 32);  # resp_size=32
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id = $cli->send("req");
    my ($req, $rid) = $srv->recv;
    eval { $srv->reply($rid, "x" x 33) };
    like $@, qr/response too long/, 'reply too long: croaks';

    # reply with exactly max size
    my $ok = $srv->reply($rid, "y" x 32);
    ok $ok, 'reply at max size: ok';
    my $resp = $cli->get($id);
    is length($resp), 32, 'got max-size response';
    is $resp, "y" x 32, 'max-size response matches';

    $srv->unlink;
}

# Arena exhaustion: many large requests fill the arena
{
    my $path = tmpnam();
    # tiny arena (4096), large messages, queue cap=8
    my $srv = Data::ReqRep::Shared->new($path, 8, 8, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $big = "A" x 1000;  # 1000 bytes per msg, arena=4096
    my @ids;
    my $sent = 0;
    for (1..8) {
        my $id = $cli->send($big);
        if (defined $id) {
            push @ids, $id;
            $sent++;
        } else {
            last;  # queue full or arena full
        }
    }
    ok $sent >= 1, "arena exhaustion: sent $sent before full";
    ok $sent < 8, "arena exhaustion: couldn't send all 8 (arena too small)";

    # drain and verify data integrity
    for my $id (@ids) {
        my ($req, $rid) = $srv->recv;
        is length($req), 1000, 'arena exhaustion: recv data ok';
        $srv->reply($rid, "ok");
        $cli->get($id);
    }

    $srv->unlink;
}

# Slot exhaustion: more concurrent requests than resp_slots
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 32, 2, 64);  # only 2 slots
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id1 = $cli->send("r1");
    my $id2 = $cli->send("r2");
    ok defined $id1, 'slot exhaustion: slot 1 ok';
    ok defined $id2, 'slot exhaustion: slot 2 ok';

    my $id3 = $cli->send("r3");
    ok !defined $id3, 'slot exhaustion: 3rd send returns undef (no slots)';

    # free a slot, then send should work
    my ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id1);

    $id3 = $cli->send("r3");
    ok defined $id3, 'slot exhaustion: 3rd send ok after freeing slot';

    # cleanup
    ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id2);
    ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id3);

    $srv->unlink;
}

# clear() with in-flight requests releases slots
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id1 = $cli->send("x1");
    my $id2 = $cli->send("x2");
    is $cli->pending, 2, 'clear: 2 pending before clear';
    is $srv->size, 2, 'clear: 2 in queue';

    $srv->clear;
    is $srv->size, 0, 'clear: queue empty';
    is $cli->pending, 0, 'clear: slots released (0 pending)';

    # get on cleared slots returns undef (stale gen)
    my $r1 = $cli->get($id1);
    ok !defined $r1, 'clear: get on cleared slot returns undef';

    # new requests work after clear
    my $id3 = $cli->send("after_clear");
    ok defined $id3, 'clear: send after clear ok';
    my ($rq, $ri) = $srv->recv;
    is $rq, 'after_clear', 'clear: recv after clear ok';
    $srv->reply($ri, "ok");
    is $cli->get($id3), 'ok', 'clear: round-trip after clear';

    $srv->unlink;
}

# req_wait timeout
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # no server processing — req_wait should timeout
    my $resp = $cli->req_wait("no_server", 0.05);
    ok !defined $resp, 'req_wait timeout: returns undef';
    # slot should be freed (cancel + drain)
    is $cli->pending, 0, 'req_wait timeout: slot freed';

    # drain the queued request
    $srv->recv;
    $srv->unlink;
}

# send_wait timeout (queue full)
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 2, 4, 64);  # tiny queue cap=2
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id1 = $cli->send("f1");
    my $id2 = $cli->send("f2");
    ok defined $id1, 'queue full: send 1 ok';
    ok defined $id2, 'queue full: send 2 ok';

    # queue is full, non-blocking send fails
    my $id3 = $cli->send("f3");
    ok !defined $id3, 'queue full: send 3 returns undef';

    # send_wait with timeout
    $id3 = $cli->send_wait("f3", 0.01);
    ok !defined $id3, 'queue full: send_wait times out';

    # cleanup
    for ($id1, $id2) {
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, "ok");
        $cli->get($_);
    }

    $srv->unlink;
}

done_testing;
