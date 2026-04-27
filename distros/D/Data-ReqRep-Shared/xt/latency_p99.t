use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# p99/p50 latency guard: catches tail-latency regressions from
# futex-wake storms, lock-convoy patterns, or accidental serialization.

use Data::ReqRep::Shared;

plan tests => 4;

my $rr = Data::ReqRep::Shared->new_memfd("p99", 64, 16, 128);

my $N = 500;

my $server = fork // die "fork: $!";
if (!$server) {
    my $r = Data::ReqRep::Shared->new_from_fd($rr->memfd);
    my $handled = 0;
    my $deadline = time + 20;
    while (time < $deadline && $handled < $N) {
        my $req = $r->recv_wait(1);
        last unless $req;
        $r->reply($req, "ok");
        $handled++;
    }
    exit 0;
}

# Client: measure roundtrip for each call
my $c = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);

my @latencies;
for (1..$N) {
    my $t0 = time;
    my $reply = $c->req_wait("ping", 5);
    push @latencies, time - $t0 if defined $reply;
}

ok scalar(@latencies) >= $N * 0.95, "got at least 95% replies";

waitpid $server, 0;

my @sorted = sort { $a <=> $b } @latencies;
my $p50 = $sorted[int(@sorted * 0.50)];
my $p99 = $sorted[int(@sorted * 0.99)];
my $max = $sorted[-1];

diag sprintf "  p50 = %.3f ms", $p50 * 1000;
diag sprintf "  p99 = %.3f ms", $p99 * 1000;
diag sprintf "  max = %.3f ms", $max * 1000;

cmp_ok $p50, '<', 0.050, "p50 < 50ms (${\sprintf '%.1fms', $p50*1000})";
cmp_ok $p99, '<', 0.200, "p99 < 200ms (${\sprintf '%.1fms', $p99*1000})";
cmp_ok $p99 / ($p50 || 1e-9), '<', 20, "p99/p50 ratio sane (catches lock-convoy)";
