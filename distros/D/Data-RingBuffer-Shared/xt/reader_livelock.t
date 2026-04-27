use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::RingBuffer::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Reader retries up to 8 times on seqlock torn-read detection. Under
# very high writer pressure, reader can exhaust the budget and return 0
# (indeterminate). Measure the failure rate — excessive livelock would
# indicate a tuning problem.

my $cap = 16;
my $r = Data::RingBuffer::Shared::Int->new(undef, $cap);

# Two fast writers
my @pids;
for my $w (1..2) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $t0 = time;
        while (time - $t0 < 2) { $r->write($w * 10_000 + int(rand 1_000_000)) }
        _exit(0);
    }
    push @pids, $pid;
}

# Reader polls `latest` repeatedly. Count successes vs failures.
my $successes = 0;
my $failures  = 0;
my $t0 = time;
while (time - $t0 < 2) {
    my $v = $r->latest(0);
    if (defined $v) { $successes++ } else { $failures++ }
}
waitpid($_, 0) for @pids;

my $fail_rate = $successes == 0 ? 1.0 : $failures / ($successes + $failures);
diag sprintf("reader: %d ok, %d miss (%.1f%%), writer count=%d",
             $successes, $failures, $fail_rate * 100, $r->count);

cmp_ok $successes, '>', 0, 'reader got at least one sample';
cmp_ok $fail_rate, '<', 0.95,
    sprintf("failure rate %.1f%% < 95%% — retry budget not exhausted constantly", $fail_rate * 100);

done_testing;
