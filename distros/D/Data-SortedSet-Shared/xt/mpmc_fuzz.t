use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# Many processes concurrently add/incr/remove/query a shared set over an
# OVERLAPPING member space (so they genuinely contend on the same members, unlike
# fork_live.t's disjoint ranges). Afterwards verify global integrity: the B+tree
# structural invariants hold, every member is reachable in order, and the index
# population matches count -- i.e. no torn split/merge or counts drift under
# concurrent writers.

my $PROCS   = $ENV{MPMC_PROCS} || 6;
my $OPS     = $ENV{MPMC_OPS}   || 20_000;
my $MEMBERS = $PROCS * 2000;                 # shared member space; also the capacity
my $z = Data::SortedSet::Shared->new(undef, $MEMBERS);

my @pids;
for my $w (0 .. $PROCS - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        srand($w * 7919 + $$);
        for (1 .. $OPS) {
            my $m = int(rand($MEMBERS));
            my $r = rand();
            if    ($r < 0.45) { $z->add($m, rand() * 1000) }
            elsif ($r < 0.65) { $z->incr($m, rand() < 0.5 ? 1 : -1) }
            elsif ($r < 0.80) { $z->remove($m) }
            elsif ($r < 0.90) { $z->rank($m) }
            elsif ($r < 0.97) { $z->range_by_score(100, 200, limit => 50) }
            else              { my @x = $z->pop_min }
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? != 0 }

is $fails, 0, 'no worker crashed under concurrent add/incr/remove/pop/query';
cmp_ok $z->count, '<=', $MEMBERS, 'count within capacity: ' . $z->count;
ok $z->_validate, 'B+tree structurally consistent after concurrent multi-process churn';

my @all;
$z->each(sub { push @all, $_[0] });
is scalar(@all), $z->count, 'every live member reachable in order (each count == count)';

my $st = $z->stats;
is $st->{count}, $z->count, 'stats count consistent';

# in-order check: each() must already be sorted by (score, member)
my $sorted = 1;
my @pairs;
$z->each(sub { push @pairs, [$_[1], $_[0]] });
for my $i (1 .. $#pairs) {
    my ($ps, $pm) = @{ $pairs[$i - 1] };
    my ($cs, $cm) = @{ $pairs[$i] };
    $sorted = 0, last if $ps > $cs || ($ps == $cs && $pm >= $cm);
}
ok $sorted, 'members remain in strict (score, member) order after churn';

done_testing;
