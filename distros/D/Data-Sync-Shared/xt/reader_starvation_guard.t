use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

# Regression: Sync RWLock sustained reader contention must not deadlock.
# Fixed in Pass 2 by adding rwlock_writers_waiting counter.

my $rw = Data::Sync::Shared::RWLock->new(undef);

my $N = 6;
my $OPS = 5000;

my $t0 = time;
my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) { $rw->rdlock; $rw->rdunlock }
        _exit(0);
    }
    push @pids, $pid;
}

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? }
my $dt = time - $t0;

is $fails, 0, "$N readers × $OPS rdlock/rdunlock completed";
ok $dt < 10, sprintf('completed in %.2fs', $dt);

done_testing;
