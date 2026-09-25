use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

use Data::ReqRep::Shared;

my $rr = Data::ReqRep::Shared->new_memfd("cw", 16, 8, 64);

my $c1 = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
my $id = $c1->send("ping");
ok defined $id, "sent request id=$id";

my $t0 = time;
my $pid = fork // die;
if (!$pid) {
    my $c2 = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
    usleep 200_000;
    $c2->cancel($id);
    _exit(0);
}

my $reply = $c1->get_wait($id, 3);
my $elapsed = time - $t0;

waitpid $pid, 0;

ok !defined $reply, "get_wait returns undef after cancel";
cmp_ok $elapsed, '<', 1,   # below the 2 s tick, which would end the wait without the wake
    "get_wait returned promptly after cancel (${\sprintf '%.3f', $elapsed}s)";
cmp_ok $elapsed, '>=', 0.15, "get_wait waited at least until cancel fired";

done_testing;
