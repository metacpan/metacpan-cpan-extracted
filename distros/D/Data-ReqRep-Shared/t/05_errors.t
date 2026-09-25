use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 32);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id = $cli->send("req");
    my ($req, $rid) = $srv->recv;
    eval { $srv->reply($rid, "x" x 33) };
    like $@, qr/response too long/, 'reply too long: croaks';

    my $ok = $srv->reply($rid, "y" x 32);
    ok $ok, 'reply at max size: ok';
    my $resp = $cli->get($id);
    is length($resp), 32, 'got max-size response';
    is $resp, "y" x 32, 'max-size response matches';

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 8, 64, 4096);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $big = "A" x 1000;
    my @ids;
    my $sent = 0;
    for (1..8) {
        my $id = $cli->send($big);
        if (defined $id) {
            push @ids, $id;
            $sent++;
        } else {
            last;
        }
    }
    ok $sent >= 1, "arena exhaustion: sent $sent before full";
    ok $sent < 8, "arena exhaustion: couldn't send all 8 (arena too small)";

    for my $id (@ids) {
        my ($req, $rid) = $srv->recv;
        is length($req), 1000, 'arena exhaustion: recv data ok';
        $srv->reply($rid, "ok");
        $cli->get($id);
    }

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 32, 2, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id1 = $cli->send("r1");
    my $id2 = $cli->send("r2");
    ok defined $id1, 'slot exhaustion: slot 1 ok';
    ok defined $id2, 'slot exhaustion: slot 2 ok';

    my $id3 = $cli->send("r3");
    ok !defined $id3, 'slot exhaustion: 3rd send returns undef (no slots)';

    my ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id1);

    $id3 = $cli->send("r3");
    ok defined $id3, 'slot exhaustion: 3rd send ok after freeing slot';

    ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id2);
    ($rq, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id3);

    $srv->unlink;
}

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

    my $r1 = $cli->get($id1);
    ok !defined $r1, 'clear: get on cleared slot returns undef';

    my $id3 = $cli->send("after_clear");
    ok defined $id3, 'clear: send after clear ok';
    my ($rq, $ri) = $srv->recv;
    is $rq, 'after_clear', 'clear: recv after clear ok';
    $srv->reply($ri, "ok");
    is $cli->get($id3), 'ok', 'clear: round-trip after clear';

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id_recv = $cli->send("received");
    my $id_repl = $cli->send("answered");
    my (undef, $ri_recv) = $srv->recv;
    my (undef, $ri_repl) = $srv->recv;
    ok $srv->reply($ri_repl, "unread"), 'clear: reply before clear ok';
    $cli->send("queued");

    $srv->clear;
    ok !$srv->reply($ri_recv, "late"), 'clear: reply to a received request returns false';
    is $cli->get($id_repl), undef, 'clear: an unread reply is discarded';
    is $srv->stats->{arena_used}, 0, 'clear: arena empty';

    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 8, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $resp = $cli->req_wait("no_server", 0.05);
    ok !defined $resp, 'req_wait timeout: returns undef';
    is $cli->pending, 0, 'req_wait timeout: slot freed';

    $srv->recv;
    $srv->unlink;
}

{
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 2, 4, 64);
    my $cli = Data::ReqRep::Shared::Client->new($path);

    my $id1 = $cli->send("f1");
    my $id2 = $cli->send("f2");
    ok defined $id1, 'queue full: send 1 ok';
    ok defined $id2, 'queue full: send 2 ok';

    my $id3 = $cli->send("f3");
    ok !defined $id3, 'queue full: send 3 returns undef';

    $id3 = $cli->send_wait("f3", 0.01);
    ok !defined $id3, 'queue full: send_wait times out';

    for ($id1, $id2) {
        my ($r, $ri) = $srv->recv;
        $srv->reply($ri, "ok");
        $cli->get($_);
    }

    $srv->unlink;
}

{
    my $path = tmpnam();
    Data::ReqRep::Shared->new($path, 8, 2, 32);
    my $poke = sub {
        open my $fh, '+<', $path or die $!;
        binmode $fh;
        seek $fh, $_[0], 0;
        print {$fh} pack 'L', $_[1];
        close $fh;
    };
    $poke->(4, 2);
    ok !eval { Data::ReqRep::Shared::Client->new($path); 1 }, 'a file of another format is refused';
    like $@, qr/another version of this module \(format 2, this one reads \d+\); remove it/,
        '  with a message naming the version';
    $poke->(0, 0xdeadbeef);
    ok !eval { Data::ReqRep::Shared->new($path, 8, 2, 32); 1 }, 'a corrupt file is refused';
    like $@, qr/invalid or incompatible reqrep file/, '  as before';
    unlink $path;
}

{
    my $dir = tmpnam();
    my $long = join '/', $dir, 'd' x 140, 'e' x 140;
    ok !eval { Data::ReqRep::Shared::Client->new("$long/q.shm"); 1 }, 'a missing file under a long path is refused';
    like $@, qr{/q\.shm\): \S}, '  with the reason';
    mkdir $_ or die $! for $dir, "$dir/" . 'd' x 140, $long;
    Data::ReqRep::Shared->new("$long/q.shm", 8, 2, 32);
    open my $fh, '+<', "$long/q.shm" or die $!;
    seek $fh, 4, 0;
    print {$fh} pack 'L', 2;
    close $fh;
    ok !eval { Data::ReqRep::Shared::Client->new("$long/q.shm"); 1 }, 'a file of another format under a long path is refused';
    like $@, qr/format 2, this one reads \d+\); remove it and create it again/, '  with the whole message';
    unlink "$long/q.shm";
    rmdir $_ for $long, "$dir/" . 'd' x 140, $dir;
}

done_testing;
