use strict; use warnings; use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SpatialHash::Shared;

# A child that uses the map after fork must claim its OWN reader slot (the
# fork-generation counter forces a re-claim) instead of corrupting the parent's
# slot accounting. The parent uses the map BEFORE forking so its slot is live.

my $s = Data::SpatialHash::Shared->new(undef, 100_000, 0, 1.0);
$s->insert(rand()*1000, rand()*1000, $_) for 1 .. 1000;
$s->query_radius(500, 500, 10) for 1 .. 50;     # parent claims a reader slot

my @pids;
for my $w (1 .. 4) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {                                  # child reuses the inherited handle post-fork
        for (1 .. 5000) {
            $s->query_radius(rand()*1000, rand()*1000, 8);
            $s->insert(rand()*1000, rand()*1000, $w * 1_000_000 + $_) if $_ % 10 == 0;
        }
        _exit(0);
    }
    push @pids, $pid;
}
$s->query_radius(rand()*1000, rand()*1000, 8) for 1 .. 5000;   # parent works concurrently
my $fails = 0;
waitpid($_, 0), ($fails += ($? != 0)) for @pids;

is $fails, 0, 'parent + children operate concurrently after fork (own reader slots, no deadlock)';
my @all = $s->query_aabb(-1, -1, 1001, 1001);
is scalar(@all), $s->count, 'state consistent after concurrent post-fork use';

done_testing;
