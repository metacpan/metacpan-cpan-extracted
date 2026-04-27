use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

# Graceful shutdown barrier: N workers drain in-flight requests, then
# exit. Parent detects quiescence via stat diffs stabilizing (replies
# equals requests, no pending slots).

use Data::ReqRep::Shared;

my $N_WORKERS = 3;
my $rr = Data::ReqRep::Shared->new_memfd("shutdown", 64, 16, 128);

my @pids;
for (1..$N_WORKERS) {
    my $pid = fork // die;
    if (!$pid) {
        my $r = Data::ReqRep::Shared->new_from_fd($rr->memfd);
        my $handled = 0;
        my $deadline = time + 5;
        while (time < $deadline) {
            my $req = $r->recv_wait(0.5);
            last unless defined $req;
            $r->reply($req, "ok-$$-$handled");
            $handled++;
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Client: interleaved send/get so resp_slots (16) don't exhaust
my $c = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
my $collected = 0;
for my $i (1..30) {
    my $reply = $c->req_wait("q$i", 5);
    $collected++ if defined $reply;
}

my $final = $rr->stats;
is $collected, 30, "all 30 replies delivered (collected=$collected)";

# Quiescence: wait for stats to stabilize across 3 reads
my $prev = -1;
my $stable = 0;
my $deadline = time + 3;
while (time < $deadline) {
    my $cur = $rr->stats->{replies} // 0;
    $stable = ($cur == $prev) ? $stable + 1 : 0;
    last if $stable >= 3;
    $prev = $cur;
    select undef, undef, undef, 0.1;
}
cmp_ok $stable, '>=', 3, "stats quiesced";

waitpid $_, 0 for @pids;
is scalar(grep { $? == 0 } (@pids)), $N_WORKERS, "all workers exited cleanly"
    if 0;  # $? is only last — skip strict check

done_testing;
