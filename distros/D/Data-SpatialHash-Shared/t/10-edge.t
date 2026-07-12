use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# coincident points: many entries at the exact same coordinate
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my @h = map { $s->insert(5.5, 5.5, $_) } 1..5;
    is $s->count, 5, '5 coincident entries';
    is_deeply [sort { $a <=> $b } $s->query_cell(5.5, 5.5)],     [1,2,3,4,5], 'all coincident in one cell';
    is_deeply [sort { $a <=> $b } $s->query_radius(5.5, 5.5, 0.1)], [1,2,3,4,5], 'all coincident in radius';
    $s->remove($h[2]);
    is_deeply [sort { $a <=> $b } $s->query_cell(5.5, 5.5)], [1,2,4,5], 'remove one coincident';
    $s->move($h[0], 9.5, 9.5);
    is_deeply [sort { $a <=> $b } $s->query_cell(5.5, 5.5)], [2,4,5], 'move one of the coincident away';
    is_deeply [$s->query_cell(9.5, 9.5)], [1], 'moved one found at new cell';
}

# int64 payload extremes (exact IVs, not the 2^63 NV literal)
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my $min = -9223372036854775807 - 1;   # INT64_MIN, exact
    my $max = 9223372036854775807;        # INT64_MAX, exact
    my %h = ( neg => $s->insert(1,1,-42), zero => $s->insert(2,2,0),
              min => $s->insert(3,3,$min), max => $s->insert(4,4,$max) );
    is $s->value($h{neg}),  -42,  'negative payload round-trips';
    is $s->value($h{zero}),  0,   'zero payload';
    is $s->value($h{min}),  $min, 'INT64_MIN payload round-trips';
    is $s->value($h{max}),  $max, 'INT64_MAX payload round-trips';
    my %got = map { $_ => 1 } $s->query_aabb(0,0,5,5);
    ok $got{-42} && $got{0} && $got{$min} && $got{$max}, 'extreme payloads returned by query';
}

# move: same-cell (no rebucket) vs cross-cell (rebucket)
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my $h = $s->insert(5.1, 5.1, 1);
    $s->move($h, 5.9, 5.9);                              # still cell (5,5)
    is_deeply [$s->query_cell(5, 5)], [1], 'same-cell move keeps entry in cell';
    { my @p = $s->position($h); ok abs($p[0]-5.9)<1e-9 && abs($p[1]-5.9)<1e-9 && $p[2]==0, 'same-cell move updates position'; }
    $s->move($h, 8.1, 8.1);                              # cell (8,8)
    is_deeply [$s->query_cell(5, 5)], [], 'cross-cell move leaves old cell';
    is_deeply [$s->query_cell(8, 8)], [1], 'cross-cell move enters new cell';
}

# slot reuse after remove
{
    my $s = Data::SpatialHash::Shared->new(undef, 4, 0, 1.0);
    my @h = map { $s->insert($_, 0, $_) } 1..4;
    is $s->insert(9, 9, 9), undef, 'pool full';
    $s->remove($h[1]); $s->remove($h[3]);
    is $s->count, 2, 'two removed';
    ok !$s->has($h[1]), 'removed handle is dead';
    ok !$s->move($h[1], 5, 5), 'move on a removed handle returns false';
    ok defined($s->insert(7, 7, 7)) && defined($s->insert(8, 8, 8)), 'freed slots reused';
    is $s->insert(9, 9, 9), undef, 'pool full again';
    is $s->count, 4, 'count back to capacity';
}

done_testing;
