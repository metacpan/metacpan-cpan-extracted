use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Stack::Shared;

my $OPS     = $ENV{STRESS_OPS}     || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 8;
diag "stress: $WORKERS workers x $OPS push+pop each";

my $stk = Data::Stack::Shared::Int->new(undef, 64);
my $t0 = time;
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            $stk->push_wait($$, 1.0);
            $stk->pop_wait(1.0);
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
is $stk->size, 0, "stack empty after stress";
diag sprintf "%.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

# Str stress
my $ss = Data::Stack::Shared::Str->new(undef, 64, 32);
@pids = ();
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..($OPS / 10)) {
            $ss->push_wait("w=$$ i=$_", 1.0);
            $ss->pop_wait(1.0);
        }
        _exit(0);
    }
    push @pids, $pid;
}
$fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
is $fails, 0, "Str stress: no failures";
is $ss->size, 0, "Str stack empty";

done_testing;
