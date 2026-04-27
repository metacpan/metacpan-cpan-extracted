use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

# Contention profile: under N producers + N consumers, pathological
# send_full/recv_empty counts indicate lock-convoy or wake/wait storms.

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("cont", 64);
my $MSG_PER_PROD = 500;
my $N = 4;

my @pids;

# Producers
for my $i (1..$N) {
    my $pid = fork // die;
    if (!$pid) {
        my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
        for (1..$MSG_PER_PROD) {
            $q2->push_wait($i * 10000 + $_, 5);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Consumers
my $TOTAL = $N * $MSG_PER_PROD;
my @cpids;
for (1..$N) {
    my $pid = fork // die;
    if (!$pid) {
        my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
        my $got = 0;
        while ($got < $TOTAL / $N + 50) {
            my $v = $q2->pop_wait(5);
            last unless defined $v;
            $got++;
        }
        _exit(0);
    }
    push @cpids, $pid;
}

waitpid $_, 0 for (@pids, @cpids);

my $stats = $q->stats;
my $send_full  = $stats->{send_full}  // 0;
my $recv_empty = $stats->{recv_empty} // 0;
my $pushes     = $stats->{pushes}     // $TOTAL;

diag sprintf "  pushes=%d send_full=%d recv_empty=%d",
    $pushes, $send_full, $recv_empty;

# Pathological thresholds (conservative — tune only if noisy in CI):
cmp_ok $send_full, '<', $TOTAL, "send_full < total pushes ($send_full < $TOTAL)";
cmp_ok $recv_empty, '<', $TOTAL, "recv_empty < total ($recv_empty < $TOTAL)";

done_testing;
