use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

# ============================================================
# 1. Response at exact resp_data_max boundary
# ============================================================
{
    my $path = tmpnam();
    my $resp_max = 4096;
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, $resp_max);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # exactly resp_data_max
    my $big_resp = "R" x $resp_max;
    my $id = $cli->send("req");
    my ($rq, $ri) = $srv->recv;
    my $ok = $srv->reply($ri, $big_resp);
    ok $ok, "reply at exact resp_data_max ($resp_max bytes)";
    my $resp = $cli->get($id);
    is length($resp), $resp_max, 'got full-size response';
    is $resp, $big_resp, 'response data matches';

    # one byte over
    $id = $cli->send("req2");
    ($rq, $ri) = $srv->recv;
    eval { $srv->reply($ri, "X" x ($resp_max + 1)) };
    like $@, qr/response too long/, 'reply over resp_data_max croaks';
    # slot is still ACQUIRED — reply failed. Cancel it.
    $cli->cancel($id);

    $srv->unlink;
}

# ============================================================
# 2. Large requests filling the arena
# ============================================================
{
    my $path = tmpnam();
    my $arena = 16384;
    my $srv = Data::ReqRep::Shared->new($path, 16, 8, 64, $arena);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # Single request nearly as large as the arena
    my $huge = "A" x ($arena - 64);  # leave room for alignment
    my $id = $cli->send($huge);
    ok defined $id, 'large request near arena size: send ok';
    my ($rq, $ri) = $srv->recv;
    is length($rq), length($huge), 'large request recv ok';
    is $rq, $huge, 'large request data matches';
    $srv->reply($ri, "ok");
    $cli->get($id);

    # Fill arena with multiple medium messages
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

    # drain all
    for my $mid (@ids) {
        my ($r, $ri2) = $srv->recv;
        is length($r), length($medium), 'medium msg data intact';
        $srv->reply($ri2, "ok");
        $cli->get($mid);
    }

    $srv->unlink;
}

# ============================================================
# 3. Request exactly at 2GB-1 boundary (packed_len mask)
#    We can't actually allocate 2GB, but verify the limit check
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 4, 2, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # The limit is REQREP_STR_LEN_MASK = 0x7FFFFFFF (2GB-1).
    # We can't test the actual boundary (would need 2GB of RAM),
    # but we verify that normal large-ish messages work.
    my $big = "C" x 3000;
    my $id = $cli->send($big);
    ok defined $id, 'large request (3KB): send ok';
    my ($r, $ri) = $srv->recv;
    is length($r), 3000, 'large request: recv length ok';
    $srv->reply($ri, "ok");
    $cli->get($id);

    $srv->unlink;
}

# ============================================================
# 4. Empty response (zero-length)
# ============================================================
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

# ============================================================
# 5. resp_data_max = 0 (ack-only pattern)
# ============================================================
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

    # non-empty reply should croak
    $id = $cli->send("try_data");
    ($rq, $ri) = $srv->recv;
    eval { $srv->reply($ri, "x") };
    like $@, qr/response too long/, 'ack-only: non-empty reply croaks';
    $cli->cancel($id);

    $srv->unlink;
}

# ============================================================
# 6. Arena wraparound with large messages
# ============================================================
{
    my $path = tmpnam();
    my $arena = 8192;
    my $srv = Data::ReqRep::Shared->new($path, 8, 8, 64, $arena);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    # Send messages that force arena wrap multiple times
    my $msg = "W" x 2000;  # 2000 bytes + 8-byte align = 2000 bytes alloc
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
