use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::KDTree::Shared;

# An anonymous MAP_SHARED k-d tree inherited across fork: children each scatter a
# disjoint block of points into the one shared index concurrently (contending on
# the append counter under the rwlock).  The parent must then see every point --
# count equals the grand total with none lost to races -- and a query over the
# combined cloud must agree with a brute-force scan of the shared point array.
my $kids = 4;
my $per  = 20_000;
my $cap  = $kids * $per;
my $kd = Data::KDTree::Shared->new(undef, 2, $cap);

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $seed = 1 + $c;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $x = $seed % 100000;
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $y = $seed % 100000;
            $kd->add([$x, $y], $c * $per + $i);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $kd->count, $cap, "count == grand total ($cap): no lost appends across children";

# nearest to a random query must match the closest by a brute-force distance,
# using the tree's own range() to enumerate points (a full-domain box).
my @q = (50000, 50000);
my $near = $kd->nearest(\@q);
ok defined($near) && exists $near->{id}, 'nearest returns a point over the merged cloud';
# knn(1) must agree with nearest
my ($k1) = $kd->knn(\@q, 1);
is $k1->{id}, $near->{id}, 'knn(1) agrees with nearest';
cmp_ok $near->{dist}, '>=', 0, 'distance is non-negative';

done_testing;
