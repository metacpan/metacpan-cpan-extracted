use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# Chaos monkey soak: run N workers for ~10 seconds; randomly SIGKILL
# and respawn 1-2 at a time. System must converge: final used count
# is 0 after all workers exit.

use Data::Pool::Shared;

my $DURATION = 10;
my $POOL_CAP = 64;

my $p = Data::Pool::Shared::I64->new_memfd("chaos", $POOL_CAP);

sub spawn_worker {
    my $pid = fork // die;
    if (!$pid) {
        my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
        while (1) {
            my $s = $p2->alloc;
            last unless defined $s;
            $p2->set($s, $$);
            usleep int(rand(5000));
            $p2->free($s);
        }
        _exit(0);
    }
    return $pid;
}

my %workers;
for (1..4) {
    my $pid = spawn_worker();
    $workers{$pid} = 1;
}

my $deadline = time + $DURATION;
my $kills = 0;
my $spawns = 0;

while (time < $deadline) {
    usleep int(rand(500_000) + 300_000);   # 0.3 - 0.8s

    # Kill a random worker
    my @pids = keys %workers;
    next unless @pids;
    my $victim = $pids[int rand @pids];
    kill 'KILL', $victim;
    waitpid $victim, 0;
    delete $workers{$victim};
    $kills++;

    # Reclaim stale slots
    $p->recover_stale;

    # Respawn
    $workers{spawn_worker()} = 1;
    $spawns++;
}

# Kill all remaining workers gracefully
for my $pid (keys %workers) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
}

# Final recovery
my $recovered = $p->recover_stale;

diag "kills=$kills spawns=$spawns final_recovered=$recovered";

is $p->used, 0, "all slots freed after chaos monkey";
cmp_ok $kills, '>', 5, "at least 5 random kills";

done_testing;
