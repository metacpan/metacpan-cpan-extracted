use strict; use warnings; use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SpatialHash::Shared;

# Many processes race to fill a small map to capacity. The free-list must hand
# out each slot exactly once: total successful inserts == capacity, never more.

my $CAP   = 2000;
my $PROCS = 8;
my $s = Data::SpatialHash::Shared->new(undef, $CAP, 0, 1.0);

pipe(my $R, my $W) or die;
my @pids;
for my $w (0 .. $PROCS - 1) {
    my $pid = fork // die;
    if (!$pid) {
        close $R;
        my $ok = 0;
        # each tries far more inserts than the pool can hold
        for (1 .. $CAP) { $ok++ if defined $s->insert(rand()*100, rand()*100, $w * 1e6 + $_); }
        syswrite $W, "$ok\n";
        _exit(0);
    }
    push @pids, $pid;
}
close $W;
my $total = 0; $total += $_ for map { chomp; $_ } <$R>;
waitpid $_, 0 for @pids;

is $total, $CAP, "exactly capacity slots handed out under contention ($total == $CAP)";
is $s->count, $CAP, 'map is full, count == capacity';
is $s->insert(0, 0, -1), undef, 'further insert returns undef (no overflow)';
my @all = $s->query_aabb(-1, -1, 101, 101);
is scalar(@all), $CAP, 'every handed-out slot is a reachable, distinct entry';

done_testing;
