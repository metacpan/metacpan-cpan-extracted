use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# Prefork worker pool + heartbeat pattern. Parent allocates one slot per
# worker; workers write periodic timestamps; parent detects a worker that
# stopped heartbeating and recover_stale reclaims its slot.

use Data::Pool::Shared;

my $N_WORKERS = 4;
my $p = Data::Pool::Shared::I64->new_memfd("prefork", $N_WORKERS + 2);

my @pids;
my %slot_of;

for my $i (1..$N_WORKERS) {
    my $pid = fork // die;
    if (!$pid) {
        my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
        my $slot = $p2->alloc;
        # Worker: heartbeat every 100ms for up to 3s OR die at 500ms if
        # we're the "unlucky" worker #3.
        my $deadline = time + 3;
        while (time < $deadline) {
            $p2->set($slot, time * 1000);   # ms-epoch heartbeat
            _exit(13) if $i == 3 && time - $deadline > -2.5;
            usleep 100_000;
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Parent: wait for workers to start heart-beating, then observe slot occupancy
sleep 1;
is $p->used, $N_WORKERS, "$N_WORKERS worker slots allocated";

# Reap the dead one (worker #3)
waitpid $pids[2], 0;
my $died_exit = $? >> 8;
is $died_exit, 13, "worker 3 died (exit=13)";

# recover_stale must find the dead worker's slot
sleep 0.3;
my $recovered = $p->recover_stale;
cmp_ok $recovered, '>=', 1, "recover_stale reclaimed dead worker's slot";

# Remaining workers finish normally
waitpid $_, 0 for @pids[0,1,3];

done_testing;
