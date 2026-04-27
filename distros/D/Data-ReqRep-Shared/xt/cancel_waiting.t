use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# Cancel-while-waiting race: client waits on reply via get_wait; another
# process calls cancel(id). The waiter returns with a cancelled indication,
# not timeout or hang.

use Data::ReqRep::Shared;

my $rr = Data::ReqRep::Shared->new_memfd("cw", 16, 8, 64);

my $c1 = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
my $id = $c1->send("ping");
ok defined $id, "sent request id=$id";

# Fork a canceller
my $pid = fork // die;
if (!$pid) {
    my $c2 = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
    usleep 200_000;   # 200ms delay before cancelling
    $c2->cancel($id);
    _exit(0);
}

# Wait for reply: nobody will reply, but cancel fires at 200ms
my $t0 = time;
my $reply = $c1->get_wait($id, 3);
my $elapsed = time - $t0;

waitpid $pid, 0;

ok !defined $reply, "get_wait returns undef after cancel";
cmp_ok $elapsed, '<', 2.5,
    "get_wait returned promptly after cancel (${\sprintf '%.3f', $elapsed}s)";
cmp_ok $elapsed, '>=', 0.15, "get_wait waited at least until cancel fired";

done_testing;
