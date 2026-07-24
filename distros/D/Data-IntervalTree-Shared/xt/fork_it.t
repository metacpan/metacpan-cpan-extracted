use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::IntervalTree::Shared;

# An anonymous MAP_SHARED interval tree inherited across fork: children each add
# a disjoint block of intervals into the one shared index concurrently (contending
# on the append counter under the rwlock).  The parent must then see every
# interval -- count equals the grand total with none lost to races -- and a query
# over the combined set must agree with a brute-force scan.
my $kids = 4;
my $per  = 20_000;
my $cap  = $kids * $per;
my $it = Data::IntervalTree::Shared->new(undef, $cap);

# each child owns a disjoint id range and a disjoint coordinate band, and every
# child also adds one interval spanning a shared probe point so we can verify the
# merged result.
my $PROBE = 1_000_000_000;
my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = $c * 1_000_000;
        my $seed = 1 + $c;
        for my $i (1 .. $per - 1) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $lo = $base + $seed % 900_000;
            $it->add($lo, $lo + $seed % 500, $c * $per + $i);
        }
        $it->add($PROBE - 10, $PROBE + 10, $c * $per + $per);   # every child spans the probe
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $it->count, $cap, "count == grand total ($cap): no lost appends across children";

# exactly the $kids probe-spanning intervals contain $PROBE
my @at = $it->stab($PROBE);
is scalar(@at), $kids, "stab(probe) finds exactly one interval per child ($kids)";
my %ids = map { $_->{id} => 1 } @at;
is scalar(keys %ids), $kids, 'the probe hits are distinct (no duplicate/corrupt ids)';
ok !(grep { $_->{lo} != $PROBE - 10 || $_->{hi} != $PROBE + 10 } @at),
   'each probe hit carries the correct endpoints';

done_testing;
