use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

# Spurious futex wake: N consumers pop_wait on empty queue, 1 producer
# pushes 1 item + notify. All N wake up. Only 1 consumer gets the item;
# others must re-check predicate and re-block or return timeout cleanly,
# not return undef spuriously.

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("spur", 16);
my $N = 4;

pipe(my $rs, my $ws);
my @pids;
for my $i (1..$N) {
    my $pid = fork // die;
    if (!$pid) {
        close $ws;
        my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
        sysread($rs, my $go, 1);
        my $v = $q2->pop_wait(2);   # blocks up to 2s
        _exit(defined $v ? 10 : 0);  # 10 = got item, 0 = timed out
    }
    push @pids, $pid;
}
close $rs;

# All consumers at sysread; now unleash them
syswrite($ws, "G") for 1..$N;
close $ws;

# Small delay to let all enter pop_wait
select undef, undef, undef, 0.2;

# Push 1 item — only 1 consumer should get it
$q->push(42);

my $got_item = 0;
my $timed_out = 0;
my $other = 0;
for my $pid (@pids) {
    waitpid $pid, 0;
    my $ec = $? >> 8;
    if ($ec == 10) { $got_item++ }
    elsif ($ec == 0) { $timed_out++ }
    else { $other++ }
}

is $got_item, 1, "exactly 1 consumer got the single item";
is $timed_out + $got_item, $N, "other consumers timed out cleanly (no spurious returns)";
is $other, 0, "no consumer exited via error path";

done_testing;
