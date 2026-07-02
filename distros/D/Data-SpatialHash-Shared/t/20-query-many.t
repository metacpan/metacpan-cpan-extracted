use strict;
use warnings;
use Test::More;
use Data::SpatialHash::Shared;

# query_radius_many(\@Q)->[i] must equal [ query_radius(@{$Q[i]}) ] for every i,
# under a single read lock. Order within a query is not contractual, so sort both.
sub S { [ sort { $a <=> $b } @{ $_[0] } ] }

# ---- 2D: batch == per-query over a random scene ----
{
    my $s = Data::SpatialHash::Shared->new(undef, 4096, 0, 1.0);
    srand(42);
    $s->insert(rand() * 100, rand() * 100, $_) for 1 .. 500;
    my @Q = map { [ rand() * 100, rand() * 100, 5 + rand() * 15 ] } 1 .. 60;
    my $batch = $s->query_radius_many(\@Q);
    is scalar(@$batch), scalar(@Q), '2D: one result list per query';
    my $matches = 0;
    for my $i (0 .. $#Q) {
        my @single = $s->query_radius(@{ $Q[$i] });
        $matches++ if "@{ S($batch->[$i]) }" eq "@{ S(\@single) }";
    }
    is $matches, scalar(@Q), '2D: all 60 batched queries match per-query query_radius';
}

# ---- 3D ----
{
    my $s = Data::SpatialHash::Shared->new(undef, 4096, 0, 2.0);
    $s->insert($_, $_ % 50, $_ % 30, $_) for 1 .. 300;
    my @Q = map { [ rand() * 300, rand() * 50, rand() * 30, 10 ] } 1 .. 30;
    my $batch = $s->query_radius_many(\@Q);
    my $matches = 0;
    for my $i (0 .. $#Q) {
        my @single = $s->query_radius(@{ $Q[$i] });
        $matches++ if "@{ S($batch->[$i]) }" eq "@{ S(\@single) }";
    }
    is $matches, scalar(@Q), '3D: all batched queries match per-query query_radius';
}

# ---- edge cases ----
{
    my $s = Data::SpatialHash::Shared->new(undef, 256, 0, 1.0);
    $s->insert(10, 10, 111);
    $s->insert(11, 11, 222);

    is_deeply $s->query_radius_many([]), [], 'empty batch -> empty arrayref';

    my $r = $s->query_radius_many([ [ 500, 500, 3 ], [ 10, 10, 5 ] ]);
    is_deeply $r->[0], [], 'no-hit query -> empty list';
    is_deeply S($r->[1]), [ 111, 222 ], 'hitting query returns both ids';

    # malformed rows -> empty slot, siblings unaffected (cannot croak under the lock)
    my $m = $s->query_radius_many(
        [ [ 10, 10, 5 ], [ 1, 2 ], "notarray", [ 10, 10, -1 ], [ 10, 10, "Inf" + 0 ], [ 10, 10, 5 ] ]);
    is_deeply S($m->[0]), [ 111, 222 ], 'row 0 (valid) ok';
    is_deeply $m->[1], [], 'row 1 (2-elem) -> empty';
    is_deeply $m->[2], [], 'row 2 (not an arrayref) -> empty';
    is_deeply $m->[3], [], 'row 3 (negative r) -> empty';
    is_deeply $m->[4], [], 'row 4 (Inf r) -> empty';
    is_deeply S($m->[5]), [ 111, 222 ], 'row 5 (valid) ok -- siblings unaffected';
}

# ---- toroidal seam wrap: batch matches per-query near the 0/max seam ----
{
    my $s = Data::SpatialHash::Shared->new(undef, 1024, 0, 1.0, wrap => [ 100, 100 ]);
    $s->insert(1,  1,  1);
    $s->insert(99, 99, 2);
    $s->insert(50, 50, 3);
    my @Q = ([ 0, 0, 3 ], [ 99.5, 0.5, 2 ], [ 50, 50, 1 ]);
    my $batch = $s->query_radius_many(\@Q);
    for my $i (0 .. $#Q) {
        is_deeply S($batch->[$i]), S([ $s->query_radius(@{ $Q[$i] }) ]), "seam-wrap query $i matches";
    }
}

# a region-too-large query anywhere in the batch croaks -- after freeing the partial
# result tree already built for the earlier queries (exercises the error cleanup path)
{
    my $s = Data::SpatialHash::Shared->new(undef, 16, 0, 1.0);
    $s->insert(0, 0, 1);
    eval { $s->query_radius_many([ [ 0, 0, 2 ], [ 0, 0, 1e9 ] ]) };
    like $@, qr/cell/i, 'a too-large query in the batch croaks with a cells message';
    ok defined($s->insert(1, 1, 2)), 'map usable (read lock not stranded) after the TOOBIG croak';
}

done_testing;
