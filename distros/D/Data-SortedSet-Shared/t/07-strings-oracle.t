use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Data::Intern::Shared; 1 }
        or plan skip_all => 'Data::Intern::Shared is required for string-keyed sets';
}
use Data::SortedSet::Shared::Strings;

# Interleaved fuzz vs a Perl-hash oracle. NOTE: ties among equal scores break by
# interning id (first-seen order), NOT by the string key -- so every check here is
# order-independent for ties (counts, per-key scores, set membership, and the
# self-consistency of each()/rank()).
my $z = Data::SortedSet::Shared::Strings->new(max => 5000, max_keys => 5000, arena => 1 << 20);
srand(20260623);
my %sc;
for (1 .. 40_000) {
    my $k = "k" . int(rand(1500));
    my $r = rand();
    if    ($r < 0.50) { my $s = int(rand(40)) - 20; $z->add($k, $s); $sc{$k} = $s }
    elsif ($r < 0.70) { $z->remove($k); delete $sc{$k} }
    elsif ($r < 0.85) { my $d = int(rand(6)) - 3; $z->incr($k, $d); $sc{$k} = ($sc{$k} // 0) + $d }
    elsif (%sc)       { my @p = $z->pop_min; delete $sc{$p[0]} if @p }
}

is $z->count, scalar(keys %sc), 'count matches oracle';

my $sc_ok = 1;
for my $k (keys %sc) { $sc_ok = 0, last unless defined($z->score($k)) && $z->score($k) == $sc{$k} }
ok $sc_ok, 'score() matches the oracle for every key';

my @each;
$z->each(sub { push @each, [ @_ ] });
is scalar(@each), $z->count, 'each() visits every member once';

my $sorted = 1;
for my $i (1 .. $#each) { $sorted = 0, last if $each[$i][1] < $each[$i - 1][1] }
ok $sorted, 'each() is in non-decreasing score order';

my %seen = map { $_->[0] => $_->[1] } @each;
is_deeply [ sort keys %seen ], [ sort keys %sc ], 'each() keys == oracle keys';
my $score_ok = 1;
for my $k (keys %sc) { $score_ok = 0, last unless $seen{$k} == $sc{$k} }
ok $score_ok, 'each() scores == oracle scores';

my $rank_ok = 1;
for my $i (0 .. $#each) { $rank_ok = 0, last unless $z->rank($each[$i][0]) == $i }
ok $rank_ok, 'rank() agrees with each() position';

my $range_ok = 1;
for (1 .. 12) {
    my $a = int(rand(40)) - 20;
    my $b = $a + int(rand(10));
    my @want = sort grep { $sc{$_} >= $a && $sc{$_} <= $b } keys %sc;
    my @got  = sort $z->range_by_score($a, $b);
    $range_ok = 0, last unless "@got" eq "@want" && $z->count_in_score($a, $b) == scalar(@want);
}
ok $range_ok, 'range_by_score / count_in_score match the oracle (12 random ranges)';

# withscores decode + rev consistency on a fresh small set
{
    my $w = Data::SortedSet::Shared::Strings->new(max => 100);
    $w->add($_->[0], $_->[1]) for [qw(a 3)], [qw(b 1)], [qw(c 2)];
    is_deeply [ $w->range_by_rank(0, -1, withscores => 1) ], [ 'b', 1, 'c', 2, 'a', 3 ],
        'range_by_rank withscores decodes keys + scores';
    is_deeply [ $w->rev_range_by_rank(0, -1) ], [qw(a c b)], 'rev order';
}

done_testing;
