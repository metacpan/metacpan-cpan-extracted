use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

use Data::Heap::Shared;

my $DURATION = 5;
my $h = Data::Heap::Shared->new_memfd("chaos", 64);

sub spawn_worker {
    my $pid = fork // die;
    if (!$pid) {
        my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
        while (1) {
            $h2->push(int(rand(1000)), $$);
            usleep int(rand(5000));
            $h2->pop if $h2->size > 0;
        }
        _exit(0);
    }
    return $pid;
}

my %workers;
$workers{spawn_worker()} = 1 for 1..4;

my $deadline = time + $DURATION;
my $kills = 0;
while (time < $deadline) {
    usleep int(rand(300_000) + 200_000);
    my @pids = keys %workers;
    next unless @pids;
    my $victim = $pids[int rand @pids];
    kill 'KILL', $victim;
    waitpid $victim, 0;
    delete $workers{$victim};
    $kills++;
    $workers{spawn_worker()} = 1;
}

kill 'TERM', $_ for keys %workers;
waitpid $_, 0 for keys %workers;

diag "kills=$kills";
cmp_ok $kills, '>', 3, "at least 3 random kills";

# Heap should still be functional
eval { $h->push(99, 999); $h->pop };
is $@, '', "heap still functional after chaos";

done_testing;
