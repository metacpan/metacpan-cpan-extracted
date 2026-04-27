use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Heap::Shared;

my $OPS     = $ENV{STRESS_OPS}     || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 8;
diag "stress: $WORKERS workers x $OPS push+pop each";

my $h = Data::Heap::Shared->new(undef, 64);
my $t0 = time;
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            $h->push($_, $$);
            $h->pop;
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
is $h->size, 0, "heap empty after stress";
diag sprintf "%.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
