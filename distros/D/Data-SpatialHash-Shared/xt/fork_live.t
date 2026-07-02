use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SpatialHash::Shared;
my $s = Data::SpatialHash::Shared->new(undef, 100_000, 0, 1.0);  # anon MAP_SHARED -> inherited across fork
my $NKIDS = 4; my $PER = 1000;
my @pids;
for my $k (0 .. $NKIDS-1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $s->insert($k*100 + rand()*100, rand()*100, $k*1_000_000 + $_) for 1..$PER;
        exit 0;
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;
is $s->count, $NKIDS*$PER, 'all child inserts visible to parent';
my @all = $s->query_aabb(-1, -1, 1000, 1000);
is scalar(@all), $NKIDS*$PER, 'aabb sees every entry after concurrent inserts';
done_testing;
