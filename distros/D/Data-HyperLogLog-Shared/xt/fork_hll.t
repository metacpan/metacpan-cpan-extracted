use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::HyperLogLog::Shared;

# An anonymous MAP_SHARED HLL inherited across fork: children add disjoint item
# ranges concurrently (contending on the shared registers under the rwlock), and
# the parent's estimate must approximate the union cardinality. This is the
# cross-process register-merge the module exists for.
my $per = 25_000;
my $h = Data::HyperLogLog::Shared->new(undef, 14);
my @pids;
for my $k (0 .. 3) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $h->add("p$k-$_") for 1 .. $per;   # disjoint key range per child
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $total = 4 * $per;                       # disjoint -> union cardinality = 100k
my $est   = $h->count;
my $err   = abs($est - $total) / $total;
ok $err < 0.03,
   sprintf('cross-process union estimate within 3%% (got %d, want %d, err %.3f)', $est, $total, $err);

done_testing;
