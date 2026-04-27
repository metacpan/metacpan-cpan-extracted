use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# Throughput guard: catches regressions in critical-path latency that
# wouldn't show up in unit tests. Fails if throughput drops below a
# conservative floor; doesn't pin an upper bound (hardware varies).

use Data::ReqRep::Shared;

my $N = 1000;

my $rr = Data::ReqRep::Shared->new_memfd("thru", 128, 32, 64);

my $server = fork // die "fork: $!";
if (!$server) {
    my $r = Data::ReqRep::Shared->new_from_fd($rr->memfd);
    my $deadline = time + 30;
    my $handled = 0;
    while (time < $deadline && $handled < $N) {
        my $req = $r->recv_wait(1);
        last unless $req;
        $r->reply($req, "r");
        $handled++;
    }
    exit 0;
}

my $c = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);

my $t0 = time;
my $ok = 0;
for (1..$N) {
    my $reply = $c->req_wait("q", 5);
    $ok++ if defined $reply;
}
my $elapsed = time - $t0;
my $rate = $ok / $elapsed;

waitpid $server, 0;

diag sprintf "  %d replies in %.3fs = %.0f req/s", $ok, $elapsed, $rate;

is $ok, $N, "$N replies received";
cmp_ok $rate, '>', 500, "throughput >= 500 req/s (conservative floor)";

done_testing;
