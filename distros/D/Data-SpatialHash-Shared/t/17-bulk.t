use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# --- move_many ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my @h = map { $s->insert($_, 0, $_) } 1..5;
    my $moved = $s->move_many([ map { [ $h[$_-1], $_+10, $_+10 ] } 1..5 ]);
    is $moved, 5, 'move_many reports 5 moved';
    is_deeply [$s->position($h[0])], [11, 11, 0], 'move_many relocated entry (2D row)';
    $s->move_many([[ $h[1], 1, 2, 3 ]]);                       # 3D row
    is_deeply [$s->position($h[1])], [1, 2, 3], 'move_many 3D row';
    $s->remove($h[2]);
    my $m2 = $s->move_many([[ $h[2], 5, 5 ], [ $h[3], 6, 6 ]]); # dead handle skipped
    is $m2, 1, 'move_many skips a freed handle, counts the live one';
    is_deeply [$s->position($h[3])], [6, 6, 0], 'live handle in mixed batch moved';
    is $s->move_many([]), 0, 'move_many([]) moves nothing';
}

# --- insert_many ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my @ids = $s->insert_many([ [1,1,10], [2,2,20], [3,3,30,2.5] ]);
    is scalar(@ids), 3, 'insert_many returns one handle per row';
    is $s->count, 3, 'insert_many inserted all rows';
    is $s->value($ids[1]), 20, 'insert_many stored value';
    is $s->get_radius($ids[2]), 2.5, 'insert_many stored the optional radius';
    is $s->get_radius($ids[0]), 0, 'insert_many default radius 0';

    my $small = Data::SpatialHash::Shared->new(undef, 2, 0, 1.0);
    my @r = $small->insert_many([ [1,1,1], [2,2,2], [3,3,3] ]);
    ok defined($r[0]) && defined($r[1]) && !defined($r[2]), 'insert_many yields undef when the pool fills';
    is $small->count, 2, 'pool filled to capacity';

    is_deeply [$s->insert_many([])], [], 'insert_many([]) returns empty list';
    is_deeply [$s->insert_many([ [1,2,3,4,5] ])], [undef], 'insert_many skips a malformed (length-5) row';
}

# --- stats: per-cell occupancy ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    $s->insert(5.5, 5.5, $_) for 1..4;     # 4 entries in cell (5,5)
    $s->insert(9.5, 9.5, $_) for 5..6;     # 2 entries in cell (9,9)
    is $s->stats->{max_cell}, 4, 'max_cell reflects the densest cell';
    ok exists $s->stats->{max_chain}, 'max_chain still present';
}

# --- world() accessor ---
{
    is_deeply [Data::SpatialHash::Shared->new(undef, 10, 0, 1.0)->world], [], 'no wrap -> empty world()';
    is_deeply [Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, wrap => [50, 60])->world], [50, 60], 'world() 2D';
    is_deeply [Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, wrap => [10, 20, 30])->world], [10, 20, 30], 'world() 3D';
    eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, wrap => [50]) }; ok $@, 'wrap with one extent croaks';
    eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, bogus => 1) }; ok $@, 'unknown option croaks';
    eval { Data::SpatialHash::Shared->new(undef, 10, 0, 6, wrap => [50, 60]) }; ok $@, 'wrap extent not a multiple of cell_size croaks';
}

done_testing;
