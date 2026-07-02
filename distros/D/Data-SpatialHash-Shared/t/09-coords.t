use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# Negative coordinates (floor of negatives -> negative int64 cells) and
# fractional cell_size (cell-size scaling) are distinct code paths from the
# positive/unit-cell grids the other brute-force tests use.

sub d2 { my ($p,$cx,$cy) = @_; ($p->[0]-$cx)**2 + ($p->[1]-$cy)**2 }

for my $cs (0.3, 1.0, 2.5) {
    my $s = Data::SpatialHash::Shared->new(undef, 5000, 0, $cs);
    my @pts; my $v = 0;
    for my $x (-10..10) { for my $y (-10..10) {
        $s->insert($x+0.5, $y+0.5, $v); push @pts, [$x+0.5, $y+0.5, $v]; $v++;
    }}
    for my $case ([0,0,3],[-8,-8,4],[5,-5,2.5],[-9.5,9.5,5]) {
        my ($cx,$cy,$r) = @$case; my $r2 = $r*$r;
        my %got  = map { $_ => 1 } $s->query_radius($cx,$cy,$r);
        my %want = map { $pts[$_][2] => 1 } grep { d2($pts[$_],$cx,$cy) <= $r2 } 0..$#pts;
        is_deeply \%got, \%want, "cs=$cs radius ($cx,$cy,$r) over negative grid";

        my $k = 5;
        my @sorted = sort { d2($pts[$a],$cx,$cy) <=> d2($pts[$b],$cx,$cy) } 0..$#pts;
        my @gk = $s->query_knn($cx,$cy,$k);
        my %gd; $gd{ sprintf('%.6f', d2($pts[$_],$cx,$cy)) }++ for @gk;
        my %wd; $wd{ sprintf('%.6f', d2($pts[$_],$cx,$cy)) }++ for @sorted[0 .. $k-1];
        is_deeply \%gd, \%wd, "cs=$cs knn ($cx,$cy,$k) over negative grid";
    }
}

# boundary inclusivity: radius uses <= r^2, aabb edges are inclusive
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    $s->insert(3, 0, 1);   # exactly distance 3 from the origin
    ok  scalar(grep { $_ == 1 } $s->query_radius(0, 0, 3)),     'radius boundary inclusive (point at r)';
    ok !scalar(grep { $_ == 1 } $s->query_radius(0, 0, 2.999)), 'radius just inside excludes';

    $s->insert(5, 5, 2);
    ok  scalar(grep { $_ == 2 } $s->query_aabb(5, 5, 10, 10)),         'aabb low edge inclusive';
    ok  scalar(grep { $_ == 2 } $s->query_aabb(0, 0, 5, 5)),           'aabb high edge inclusive';
    ok !scalar(grep { $_ == 2 } $s->query_aabb(0, 0, 4.999, 4.999)),   'aabb just outside excludes';
}

done_testing;
