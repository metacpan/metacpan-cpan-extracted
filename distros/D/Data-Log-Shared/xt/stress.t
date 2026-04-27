use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Log::Shared;

my $OPS     = $ENV{STRESS_OPS}     || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 8;
diag "stress: $WORKERS workers x $OPS appends each";

my $log = Data::Log::Shared->new(undef, $WORKERS * $OPS * 30);
my $t0 = time;
my @pids;
for my $w (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) { $log->append(sprintf "w=%d i=%d", $w, $_) }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
is $log->entry_count, $WORKERS * $OPS, "correct entry count";
diag sprintf "%.0f appends/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

# verify all readable
my $count = 0;
$log->each_entry(sub { $count++ });
is $count, $WORKERS * $OPS, "all entries readable";

done_testing;
