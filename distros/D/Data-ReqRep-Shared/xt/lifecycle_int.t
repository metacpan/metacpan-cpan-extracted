use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# ============================================================
# 1. Rapid server create/destroy
# ============================================================
{
    for (1..1000) {
        my $srv = Data::ReqRep::Shared::Int->new(undef, 8, 4);
    }
    pass '1000 anonymous Int server create/destroy';
}

# ============================================================
# 2. Rapid client create/destroy
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 16, 8);
    for (1..2000) {
        my $cli = Data::ReqRep::Shared::Int::Client->new($path);
    }
    pass '2000 Int client create/destroy';
    $srv->unlink;
}

# ============================================================
# 3. Rapid send/cancel — no slot leak
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 256, 4);
    my $cli = Data::ReqRep::Shared::Int::Client->new($path);

    for my $i (1..5000) {
        my $id = $cli->send($i);
        next unless defined $id;
        $cli->cancel($id);
    }

    is $cli->pending, 0, 'int send/cancel x5000: no slot leak';

    # drain + verify functional
    while (my ($v, $ri) = $srv->recv) { $srv->reply($ri, 0) }
    my $id = $cli->send(999);
    ok defined $id, 'int: send works after 5000 cancel cycles';
    my ($v, $ri) = $srv->recv;
    $srv->reply($ri, 888);
    is $cli->get($id), 888, 'int: round-trip after cancel churn';

    $srv->unlink;
}

# ============================================================
# 4. 10K round-trip cycles — no leak
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 64, 4);
    my $cli = Data::ReqRep::Shared::Int::Client->new($path);

    for my $i (1..10000) {
        my $id = $cli->send($i);
        next unless defined $id;
        my ($v, $ri) = $srv->recv;
        $srv->reply($ri, $v);
        $cli->get($id);
    }

    is $cli->pending, 0, 'int 10K round-trips: no slot leak';
    is $srv->size, 0, 'int 10K round-trips: queue empty';

    $srv->unlink;
}

# ============================================================
# 5. Server DESTROY before client — no crash
# ============================================================
{
    my $path = tmpnam();
    my $cli;
    {
        my $srv = Data::ReqRep::Shared::Int->new($path, 8, 4);
        $cli = Data::ReqRep::Shared::Int::Client->new($path);
        $cli->send(42);
    }
    is $cli->size, 1, 'int: client works after server destroyed';
    undef $cli;
    pass 'int: client DESTROY after server DESTROY: no crash';
    unlink $path;
}

# ============================================================
# 6. Multiple clients — independent handles
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 64, 16);

    my @clients;
    push @clients, Data::ReqRep::Shared::Int::Client->new($path) for 1..10;

    my @ids;
    for my $i (0..9) {
        push @ids, $clients[$i]->send(100 + $i);
    }

    for (0..9) {
        my ($v, $ri) = $srv->recv;
        $srv->reply($ri, $v * 10);
    }

    for my $i (0..9) {
        is $clients[$i]->get($ids[$i]), (100 + $i) * 10,
            "int multi-client: client $i correct response";
    }

    @clients = ();
    pass 'int: 10 clients destroyed without crash';
    $srv->unlink;
}

# ============================================================
# 7. memfd handle lifecycle
# ============================================================
{
    my $srv = Data::ReqRep::Shared::Int->new_memfd("int_lc", 8, 4);
    my $fd = $srv->memfd;

    for (1..500) {
        my $cli = Data::ReqRep::Shared::Int::Client->new_from_fd($fd);
        my $id = $cli->send(1);
        if (defined $id) {
            my ($v, $ri) = $srv->recv;
            $srv->reply($ri, 2);
            $cli->get($id);
        }
    }
    pass 'int: 500 memfd client cycles';
}

# ============================================================
# 8. clear under concurrent send/recv
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared::Int->new($path, 64, 16);
    my $cli = Data::ReqRep::Shared::Int::Client->new($path);

    # fill queue
    my @ids;
    push @ids, $cli->send($_) for 1..10;
    is $cli->pending, 10, 'int clear: 10 pending before clear';

    $srv->clear;
    is $srv->size, 0, 'int clear: queue empty';
    is $cli->pending, 0, 'int clear: slots released';

    # verify Vyukov sequences are correct after clear
    for my $round (1..3) {
        my @rids;
        for my $i (1..8) {
            my $id = $cli->send($round * 100 + $i);
            push @rids, $id if defined $id;
        }
        ok scalar @rids > 0, "int clear round $round: sends work";

        for my $id (@rids) {
            my ($v, $ri) = $srv->recv;
            $srv->reply($ri, $v);
            $cli->get($id);
        }
    }

    $srv->unlink;
}

done_testing;
