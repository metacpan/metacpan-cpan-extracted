use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# Non-finite / extreme coordinates must not crash or invoke UB (cells clamp to
# +/-2^62). Plus empty-map queries and exact knn ties.

# extreme + non-finite coordinates (use string->NV to be safe on longdouble perls)
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my $inf = "Inf" + 0;
    my $nan = "NaN" + 0;
    ok defined($s->insert($inf, 0, 1)),        'insert(+Inf) does not crash';
    ok defined($s->insert($nan, 0, 2)),        'insert(NaN) does not crash';
    ok defined($s->insert(1e300, 1e300, 3)),   'insert(1e300) does not crash';
    ok defined($s->insert(-1e300, 0, 4)),      'insert(-1e300) does not crash';
    is $s->count, 4, 'all extreme inserts stored';
    ok eval { $s->query_radius(0, 0, 5); 1 },  'normal query alongside extreme entries ok';
    # the 1e300 entry clamps to the same far cell as a 1e300 knn center, so it is
    # found at g=0 -- no unbounded shell walk
    is_deeply [$s->query_knn(1e300, 1e300, 1)], [3], 'knn at an extreme coordinate finds the clamped-cell entry';
}

# empty-map queries
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    is_deeply [$s->query_radius(0, 0, 10)],     [], 'radius on empty map';
    is_deeply [$s->query_aabb(0, 0, 10, 10)],   [], 'aabb on empty map';
    is_deeply [$s->query_cell(0, 0)],           [], 'cell on empty map';
    is_deeply [$s->query_knn(0, 0, 5)],         [], 'knn on empty map returns empty';
    my $n = 0; $s->each_in_radius(0, 0, 10, sub { $n++ });
    is $n, 0, 'each_in_radius on empty map invokes nothing';
}

# exact knn ties: four equidistant points
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    $s->insert(0, 5, 1); $s->insert(0, -5, 2); $s->insert(5, 0, 3); $s->insert(-5, 0, 4);
    my @k2 = $s->query_knn(0, 0, 2);
    is scalar(@k2), 2, 'knn(k=2) among 4 equidistant ties returns exactly 2';
    my %valid = (1=>1, 2=>1, 3=>1, 4=>1);
    ok !(grep { !$valid{$_} } @k2), 'knn ties returns valid entries';
    is_deeply [sort { $a <=> $b } $s->query_knn(0, 0, 4)], [1,2,3,4], 'knn(k=4) returns all four ties';
}

done_testing;
