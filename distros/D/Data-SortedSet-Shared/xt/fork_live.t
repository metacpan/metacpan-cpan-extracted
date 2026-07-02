use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# anonymous MAP_SHARED mapping is inherited across fork; children mutate it
# concurrently and the parent must see every change with the tree still intact.
my $z = Data::SortedSet::Shared->new(undef, 100_000);
my $NKIDS = 4;
my $PER   = 1000;
my @pids;
for my $k (0 .. $NKIDS - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $z->add($k * 1_000_000 + $_, rand() * 100) for 1 .. $PER;   # disjoint member ranges
        exit 0;
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $z->count, $NKIDS * $PER, 'all child adds visible to parent';
ok $z->_validate, 'B+tree invariants hold after concurrent multi-process adds';
my @all;
$z->each(sub { push @all, $_[0] });
is scalar(@all), $NKIDS * $PER, 'each() sees every member after concurrent adds';
is $z->rank($z->at_rank(0)), 0, 'rank/at_rank round-trip after concurrent adds';
is $z->rank($z->at_rank($z->count - 1)), $z->count - 1, 'last-rank round-trip';

done_testing;
