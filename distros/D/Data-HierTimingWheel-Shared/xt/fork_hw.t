use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::HierTimingWheel::Shared;

# An anonymous MAP_SHARED hierarchical wheel inherited across fork: children each
# schedule a disjoint block of timers at delays spanning several levels,
# concurrently (contending on the free-list and bucket lists under the rwlock).
# The parent then advances past every delay and must collect exactly one fire per
# scheduled timer -- no lost schedules, no double fires, no corrupted lists or
# cascades under contention.
my $kids = 4;
my $per  = 5_000;
my $maxd = 4000;                      # spans levels 0..1 for S=64
my $cap  = $kids * $per + 16;
my $tw = Data::HierTimingWheel::Shared->new(undef, 64, 3, $cap);   # max delay 64**3 - 1

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $seed = 1 + $c;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            $tw->add(1 + $seed % $maxd, $c * $per + $i);   # delay 1..4000, unique payload
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $tw->count, $kids * $per, 'every child scheduled its timers (no lost schedules)';

my %fired;
my $dupes = 0;
for my $t (1 .. $maxd) {
    for my $p ($tw->advance(1)) { $dupes++ if $fired{$p}++; }
}
is scalar(keys %fired), $kids * $per, 'every scheduled timer fired exactly once (cascades intact under contention)';
is $dupes, 0, 'no timer fired twice';
is $tw->count, 0, 'no timers left pending after advancing past every delay';

done_testing;
