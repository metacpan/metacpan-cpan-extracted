use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

my $z = Data::SortedSet::Shared->new(undef, 20000);
srand(20260622);
my %sc;
for (1 .. 8000) {
    my $m = int(rand(1e8));
    next if exists $sc{$m};
    my $s = int(rand(25)) - 12;          # ties + negatives
    $z->add($m, $s);
    $sc{$m} = $s;
}
my @ord  = sort { $sc{$a} <=> $sc{$b} or $a <=> $b } keys %sc;   # the (score,member) order
my %rank = map { $ord[$_] => $_ } 0 .. $#ord;
my $N    = scalar @ord;

# rank / rev_rank / at_rank
my ($rk, $rv, $at) = (1, 1, 1);
for my $m (@ord)        { $rk = 0 unless $z->rank($m) == $rank{$m} }
for my $m (@ord[0..300]) { $rv = 0 unless $z->rev_rank($m) == $N - 1 - $rank{$m};
                           $at = 0 unless $z->at_rank($rank{$m}) == $m }
ok $rk, 'rank() matches oracle for every member';
ok $rv, 'rev_rank()';
ok $at, 'at_rank()';
ok !defined($z->rank(-99)),     'rank of an absent member is undef';
ok !defined($z->at_rank($N)),     'at_rank out of range is undef';
ok !defined($z->at_rank(2**32)),  'at_rank index >= 2^32 is undef (no uint32 truncation)';
ok !defined($z->at_rank(2**32 + 3)), 'at_rank 2^32+k does not alias to rank k';
is $z->at_rank(-1), $ord[$N-1], 'at_rank negative index = last';

# range_by_rank
is_deeply [$z->range_by_rank(0, 9)],   [@ord[0..9]],        'range_by_rank(0,9)';
is_deeply [$z->range_by_rank(-3, -1)], [@ord[$N-3..$N-1]],  'range_by_rank negative indices';
is_deeply [$z->rev_range_by_rank(0, 9)], [reverse @ord[$N-10..$N-1]], 'rev_range_by_rank top 10';
is_deeply [$z->range_by_rank(5, 4)],   [],                  'empty range (start > stop)';

# range_by_score / count_in_score / reverse over random ranges
my $rbs_ok = 1;
for (1 .. 20) {
    my $a = int(rand(25)) - 12;
    my $b = $a + int(rand(10));
    my @want = grep { $sc{$_} >= $a && $sc{$_} <= $b } @ord;
    $rbs_ok = 0
        unless "@{[ $z->range_by_score($a, $b) ]}" eq "@want"
            && $z->count_in_score($a, $b) == scalar(@want)
            && "@{[ $z->rev_range_by_score($b, $a) ]}" eq "@{[ reverse @want ]}";
}
ok $rbs_ok, 'range_by_score / count_in_score / rev_range_by_score match oracle (20 ranges)';
is_deeply [$z->range_by_score(-12, 12, limit => 5, offset => 10)], [@ord[10..14]], 'range_by_score limit/offset';
# large offset/limit (>= 2^32) must not truncate to a small in-range value
is_deeply [$z->range_by_score(-12, 12, offset => 2**32)], [], 'range_by_score huge offset -> empty (no uint32 truncation)';
is_deeply [$z->range_by_score(-12, 12, limit => 2**32 + 3)], \@ord, 'range_by_score huge limit -> no clamp';
is_deeply [$z->rev_range_by_score(12, -12, offset => 2**32)], [], 'rev_range_by_score huge offset -> empty';

# count_in_score INT64_MAX-sentinel correction: a member == INT64_MAX is excluded by
# ss_rank_of(max, INT64_MAX) and must be added back by the hi++ path.
{
    my $iv_max = ~0 >> 1;                              # 2**63 - 1
    my $zc = Data::SortedSet::Shared->new(undef, 10);
    $zc->add($iv_max, 5);
    $zc->add(1, 5);
    $zc->add(2, 7);
    is $zc->count_in_score(5, 5), 2, 'count_in_score includes member=INT64_MAX (sentinel hi++ correction)';
    is $zc->count_in_score(5, 7), 3, 'count_in_score [5,7] spanning the INT64_MAX member';
    is $zc->count_in_score(6, 7), 1, 'count_in_score [6,7] excludes the INT64_MAX member at score 5';
    is_deeply [$zc->range_by_score(5, 5)], [1, $iv_max], 'range_by_score orders the INT64_MAX member last';
}

# INT64_MIN as a member at the low end (mirror of the INT64_MAX sentinel: it is
# the first in-band element for ss_rank_of(min, INT64_MIN), included not excluded)
{
    my $iv_min = -(~0 >> 1) - 1;                       # -2**63
    my $zc = Data::SortedSet::Shared->new(undef, 10);
    $zc->add($iv_min, 5);
    $zc->add(1, 5);
    is $zc->count_in_score(5, 5), 2, 'count_in_score includes member=INT64_MIN at the boundary score';
    is_deeply [$zc->range_by_score(5, 5)], [$iv_min, 1], 'INT64_MIN member sorts before a positive member at equal score';
    is $zc->rank($iv_min), 0, 'INT64_MIN member ranks first at equal score';
}

# +/-Inf scores are allowed (only NaN croaks): -Inf sorts first, +Inf last
{
    my $inf = "Inf" + 0;
    my $zi = Data::SortedSet::Shared->new(undef, 10);
    $zi->add(1, $inf);
    $zi->add(2, -$inf);
    $zi->add(3, 0);
    $zi->add(4, 1e308);                                # large finite, below +Inf
    ok $zi->_validate, 'tree valid with +/-Inf scores';
    is_deeply [$zi->range_by_rank(0, -1)], [2, 3, 4, 1], '-Inf first, +Inf last, finite in between';
    my ($pmin) = $zi->peek_min;
    my ($pmax) = $zi->peek_max;
    is $pmin, 2, 'peek_min is the -Inf member';
    is $pmax, 1, 'peek_max is the +Inf member';
    is $zi->count_in_score(-$inf, $inf), 4, 'count_in_score [-Inf, +Inf] = all';
    is $zi->count_in_score(0, $inf),     3, 'count_in_score [0, +Inf] excludes the -Inf member';
    is_deeply [$zi->range_by_score(-$inf, 0)], [2, 3], 'range_by_score [-Inf, 0]';
    is $zi->score(1), $inf, 'score round-trips +Inf';
}

# withscores across the range variants + rev_range_by_score limit/offset
is_deeply [$z->range_by_rank(0, 2, withscores => 1)],
          [ $ord[0], $sc{$ord[0]}, $ord[1], $sc{$ord[1]}, $ord[2], $sc{$ord[2]} ],
          'range_by_rank withscores returns (member,score) pairs';
is_deeply [$z->rev_range_by_rank(0, 1, withscores => 1)],
          [ $ord[$N-1], $sc{$ord[$N-1]}, $ord[$N-2], $sc{$ord[$N-2]} ],
          'rev_range_by_rank withscores';
is_deeply [$z->range_by_score(-12, 12, withscores => 1, limit => 2)],
          [ $ord[0], $sc{$ord[0]}, $ord[1], $sc{$ord[1]} ],
          'range_by_score withscores + limit';
is_deeply [$z->rev_range_by_score(12, -12, limit => 3, offset => 2)],
          [ reverse @ord[$N-5 .. $N-3] ],
          'rev_range_by_score limit/offset (skip 2 from the top, take 3)';

# peek + each
is_deeply [$z->peek_min], [$ord[0],    $sc{$ord[0]}],    'peek_min';
is_deeply [$z->peek_max], [$ord[$N-1], $sc{$ord[$N-1]}], 'peek_max';
my @e;
$z->each(sub { push @e, $_[0] });
is_deeply \@e, \@ord, 'each iterates in score order';
eval { $z->each(sub { die "boom\n" }) };
like $@, qr/boom/, 'each re-throws a dying callback';

# empty set
my $empty = Data::SortedSet::Shared->new(undef, 10);
is_deeply [$empty->range_by_rank(0, 9)], [], 'empty range_by_rank';
is_deeply [$empty->peek_min], [],            'empty peek_min';
is $empty->count_in_score(0, 100), 0,        'empty count_in_score';
ok !defined($empty->rank(1)),                'empty rank';

done_testing;
