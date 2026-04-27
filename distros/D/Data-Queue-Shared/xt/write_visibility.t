use strict;
use warnings;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX qw(_exit);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# How fast is a push in process A visible to a pop in process B?
# Baseline / regression doc. Typical: single-digit microseconds.

my $q = Data::Queue::Shared::Int->new(undef, 64);
my $pid = fork // die;
if ($pid == 0) {
    # Consumer — wait for N items and drain
    my $n = 0;
    while ($n < 1000) {
        if (defined(my $v = $q->pop)) { $n++; next; }
        # small busy wait
        for (1..100) {}
    }
    _exit(0);
}

# Producer: push 1000 items, time the loop
my $t0 = [gettimeofday];
for (1..1000) {
    while (!$q->push($_)) { for (1..10) {} }
}
waitpid($pid, 0);
my $elapsed = tv_interval($t0);
my $per = $elapsed / 1000 * 1e6;

ok $per < 1000, sprintf("cross-process push-to-pop avg %.1fus < 1000us", $per);
diag sprintf("cross-process latency: %.1f us/msg, %d msgs/sec",
             $per, 1000 / $elapsed);

done_testing;
