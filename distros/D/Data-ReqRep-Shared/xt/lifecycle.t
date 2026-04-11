use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

# ============================================================
# 1. Rapid create/destroy server handles
# ============================================================
{
    for my $i (1..1000) {
        my $srv = Data::ReqRep::Shared->new(undef, 8, 4, 64);
    }
    pass '1000 anonymous server create/destroy cycles';
}

# ============================================================
# 2. Rapid create/destroy client handles
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 8, 256);

    for my $i (1..2000) {
        my $cli = Data::ReqRep::Shared::Client->new($path);
    }
    pass '2000 client create/destroy cycles';

    $srv->unlink;
}

# ============================================================
# 3. Rapid send/cancel cycles — no slot leak
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 256, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    for my $i (1..5000) {
        my $id = $cli->send("msg$i");
        next unless defined $id;
        $cli->cancel($id);
    }

    # all slots should be free
    is $cli->pending, 0, 'send/cancel x5000: no slot leak';

    # drain queue, verify functional
    while (my ($r, $ri) = $srv->recv) {
        $srv->reply($ri, "ok");  # reply may fail (cancelled), that's ok
    }

    my $id = $cli->send("after_cycles");
    ok defined $id, 'send/cancel x5000: send still works';
    my ($rq, $ri) = $srv->recv;
    is $rq, 'after_cycles', 'send/cancel x5000: recv ok';
    $srv->reply($ri, "ok");
    $cli->get($id);

    $srv->unlink;
}

# ============================================================
# 4. Rapid send/recv/reply/get cycles — no leak
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 64, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    for my $i (1..10000) {
        my $id = $cli->send("x");
        next unless defined $id;
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, "y");
        $cli->get($id);
    }

    is $cli->pending, 0, '10K round-trip cycles: no slot leak';
    is $srv->size, 0, '10K round-trip cycles: queue empty';

    $srv->unlink;
}

# ============================================================
# 5. Server DESTROY before client — no crash
# ============================================================
{
    my $path = tmpnam();
    my $cli;
    {
        my $srv = Data::ReqRep::Shared->new($path, 8, 4, 64);
        $cli = Data::ReqRep::Shared::Client->new($path);
        $cli->send("orphan");
        # $srv goes out of scope — its mmap is unmapped
    }
    # $cli still holds its own mmap of the same file
    is $cli->size, 1, 'client works after server handle destroyed';
    undef $cli;
    pass 'client DESTROY after server DESTROY: no crash';
    unlink $path;
}

# ============================================================
# 6. Multiple clients on same channel — independent handles
# ============================================================
{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 64, 16, 256);

    my @clients;
    for (1..10) {
        push @clients, Data::ReqRep::Shared::Client->new($path);
    }

    # each client sends
    my @ids;
    for my $i (0..9) {
        push @ids, $clients[$i]->send("cli$i");
    }

    # recv all, reply all
    for (0..9) {
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, "ok:$r");
    }

    # each client gets its own response
    for my $i (0..9) {
        my $resp = $clients[$i]->get($ids[$i]);
        is $resp, "ok:cli$i", "multi-client: client $i got correct response";
    }

    # destroy all clients
    @clients = ();
    pass '10 clients destroyed without crash';

    $srv->unlink;
}

# ============================================================
# 7. memfd handle lifecycle — multiple open/close cycles
# ============================================================
{
    my $srv = Data::ReqRep::Shared->new_memfd("lifecycle_test", 8, 4, 64);
    my $fd = $srv->memfd;

    for my $i (1..500) {
        my $cli = Data::ReqRep::Shared::Client->new_from_fd($fd);
        my $id = $cli->send("x");
        if (defined $id) {
            my ($r, $ri) = $srv->recv;
            $srv->reply($ri, "y");
            $cli->get($id);
        }
    }
    pass '500 memfd client open/close cycles';
}

done_testing;
