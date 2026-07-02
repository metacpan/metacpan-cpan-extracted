use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

use Data::SpatialHash::Shared;

# Mutations are not crash-atomic: a SIGKILL mid-move (between bucket unlink and
# relink) can orphan at most the one entry being moved. The structure must stay
# operable afterwards -- the lock recovers, queries/stats terminate (no chain
# cycle), and at most one entry is unreachable.

my $s = Data::SpatialHash::Shared->new(undef, 200_000, 0, 1.0);
my @h = map { $s->insert(rand()*1000, rand()*1000, $_) } 1 .. 50_000;

my $pid = fork // die "fork: $!";
if (!$pid) {
    $s->move($h[int rand @h], rand()*1000, rand()*1000) while 1;   # churn bucket chains
    exit 0;
}
select undef, undef, undef, 0.1;        # let it churn
kill 'KILL', $pid; waitpid $pid, 0;

my $ok = eval {
    local $SIG{ALRM} = sub { die "stats() hung -- possible chain cycle\n" };
    alarm 15;
    my $st  = $s->stats;                          # walks every bucket chain
    my @all = $s->query_aabb(-1, -1, 1001, 1001);
    alarm 0;
    my $delta = $st->{count} - scalar(@all);
    note "count=$st->{count} reachable=" . scalar(@all) . " max_chain=$st->{max_chain} delta=$delta";
    ok $delta >= 0 && $delta <= 1, "at most one orphaned entry after mid-move SIGKILL (delta=$delta)";
    ok defined($s->insert(1, 1, -1)), 'map still usable after the SIGKILL (lock recovered)';
    1;
};
ok $ok, 'survived mid-mutation SIGKILL without hang or crash' or diag $@;

done_testing;
