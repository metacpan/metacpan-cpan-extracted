use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::RingBuffer::Shared;

my $WORKERS = $ENV{STRESS_WORKERS} || 8;
my $OPS     = $ENV{STRESS_OPS}     || 50_000;
diag "stress: $WORKERS workers x $OPS writes each";

my $r = Data::RingBuffer::Shared::Int->new(undef, 1024);
my $t0 = time;
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) { $r->write($$) for 1..$OPS; _exit(0) }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += ($? >> 8) != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
is $r->count, $WORKERS * $OPS, "correct count";
is $r->size, 1024, "size capped at capacity";
diag sprintf "%.0f writes/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
