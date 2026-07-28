use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::TimingWheel::Shared;

# An anonymous MAP_SHARED timing wheel inherited across fork: children each
# schedule a disjoint block of timers concurrently (contending on the free-list
# and bucket lists under the rwlock).  The parent then advances the clock past
# every delay and must collect exactly one fire per scheduled timer -- no lost
# schedules, no double fires, no corrupted lists.
my $kids = 4;
my $per  = 5_000;
my $maxd = 100;
my $cap  = $kids * $per + 16;
my $tw = Data::TimingWheel::Shared->new(undef, 128, $cap);

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $seed = 1 + $c;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            $tw->add(1 + $seed % $maxd, $c * $per + $i);   # delay 1..100, unique payload
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
is scalar(keys %fired), $kids * $per, 'every scheduled timer fired exactly once';
is $dupes, 0, 'no timer fired twice (bucket lists intact under contention)';
is $tw->count, 0, 'no timers left pending after advancing past every delay';

done_testing;
