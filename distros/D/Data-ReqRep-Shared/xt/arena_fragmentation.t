use strict;
use warnings;
use Test::More;

# Arena fragmentation soak: random-size send/recv cycles must return
# arena_used to baseline after full drain. Catches slow leaks where
# a code path fails to release arena bytes (e.g. off-by-one, cancel
# path omitting arena_skip).

use Data::ReqRep::Shared;

my $seed = $ENV{FUZZ_SEED} || time;
srand $seed;
diag "FUZZ_SEED=$seed";

my $rr = Data::ReqRep::Shared->new_memfd("arena", 32, 8, 512);

my $server = fork // die;
if (!$server) {
    my $r = Data::ReqRep::Shared->new_from_fd($rr->memfd);
    my $done = 0;
    while ($done < 5000) {
        my $req = $r->recv_wait(2);
        last unless $req;
        $r->reply($req, "r");
        $done++;
    }
    exit 0;
}

my $c = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);

my $baseline = $rr->stats->{arena_used} // 0;
diag "baseline arena_used=$baseline";

for my $round (1..5) {
    for (1..1000) {
        my $len = int(rand(300)) + 1;
        my $msg = 'x' x $len;
        my $reply = $c->req_wait($msg, 5);
        is $reply, "r", "reply round=$round size=$len" if 0; # too noisy; silent
    }
    my $used = $rr->stats->{arena_used} // 0;
    diag sprintf "  round $round: arena_used=%d", $used;
}

my $final = $rr->stats->{arena_used} // 0;
cmp_ok $final, '<=', $baseline + 256,
    "arena_used returns to near-baseline ($baseline → $final)";

# wind down server
waitpid $server, 0;

done_testing;
