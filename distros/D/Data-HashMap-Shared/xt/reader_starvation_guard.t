use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::HashMap::Shared::II;

# Regression: all-reader workload (concurrent incr on same key) must not
# deadlock on rwlock's write-preferring yield. Fixed by splitting
# rwlock_writers_waiting from rwlock_waiters.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, 1024);

my $N = 6;
my $OPS = 2000;

my $t0 = time;
my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $c = Data::HashMap::Shared::II->new($path, 1024);
        for (1..$OPS) { $c->incr(42) }  # all contending on same key
        _exit(0);
    }
    push @pids, $pid;
}

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? }
my $dt = time - $t0;
unlink $path;

is $fails, 0, "$N processes × $OPS incr completed";
ok $dt < 10, sprintf('completed in %.2fs (was pre-fix: indefinite hang)', $dt);
is $m->get(42), $N * $OPS, 'final counter matches total ops';

done_testing;
