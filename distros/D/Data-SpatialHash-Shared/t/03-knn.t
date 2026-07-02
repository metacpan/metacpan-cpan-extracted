use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 5000, 0, 1.0);
my @pts; my $v = 0;
for my $x (0..19) { for my $y (0..19) {
    my ($px,$py) = ($x+0.5, $y+0.5);
    $s->insert($px,$py,$v); push @pts,[$px,$py,$v]; $v++;
}}

sub brute_knn { my ($cx,$cy,$k) = @_;
    my @sorted = sort { ($a->[0]-$cx)**2+($a->[1]-$cy)**2 <=> ($b->[0]-$cx)**2+($b->[1]-$cy)**2 } @pts;
    return [ map { $_->[2] } @sorted[0 .. $k-1] ]; }

for my $case ([10,10,1],[10,10,5],[0,0,8],[19.5,19.5,4]) {
    my ($cx,$cy,$k) = @$case;
    my @got = $s->query_knn($cx,$cy,$k);
    is scalar(@got), $k, "knn ($cx,$cy) returns $k";
    # compare as distance-sorted sets: ties may reorder, so compare the
    # multiset of squared distances, which is well-defined.
    my %gd; $gd{ sprintf('%.6f',($pts[$_]->[0]-$cx)**2+($pts[$_]->[1]-$cy)**2) }++ for @got;
    my $want = brute_knn($cx,$cy,$k);
    my %wd; $wd{ sprintf('%.6f',($pts[$_]->[0]-$cx)**2+($pts[$_]->[1]-$cy)**2) }++ for @$want;
    is_deeply \%gd, \%wd, "knn ($cx,$cy,$k) distances match brute force";
    # results must come back nearest-first (non-decreasing squared distance).
    my @d = map { ($pts[$_]->[0]-$cx)**2 + ($pts[$_]->[1]-$cy)**2 } @got;
    is_deeply \@d, [sort { $a <=> $b } @d], "knn ($cx,$cy,$k) nearest-first";
}

# regression: knn must find all k even when some live points are many cells away.
# old terminator capped Chebyshev expansion at max_ring = max_entries + 1 cells,
# so a point 50 cells away was never scanned. seen-based termination fixes it.
{
    my $sp = Data::SpatialHash::Shared->new(undef, 5, 0, 1.0);  # old cap max_ring was 6
    $sp->insert(0,0,1); $sp->insert(0.5,0.5,2); $sp->insert(50,50,3);  # 3rd far beyond old cap
    is_deeply [sort { $a <=> $b } $sp->query_knn(0,0,3)], [1,2,3],
        'knn finds all k even when some are far (max_ring regression)';
}

# k larger than population returns everything
my $tiny = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0);
$tiny->insert(0,0,1); $tiny->insert(5,5,2);
my @all = $tiny->query_knn(0,0,100);
is scalar(@all), 2, 'knn caps at population';

# k == 0 croaks
eval { $s->query_knn(0,0,0) }; ok $@, 'k=0 croaks';

# --- 3D knn: validates the 3D shell-surface enumeration against brute force ---
sub d3 { my ($p,$cx,$cy,$cz) = @_; ($p->[0]-$cx)**2 + ($p->[1]-$cy)**2 + ($p->[2]-$cz)**2 }
{
    my $s3 = Data::SpatialHash::Shared->new(undef, 5000, 0, 1.0);
    my @p3; my $w = 0;
    for my $x (0..9) { for my $y (0..9) { for my $z (0..9) {
        $s3->insert($x+0.5, $y+0.5, $z+0.5, $w);
        push @p3, [$x+0.5, $y+0.5, $z+0.5, $w]; $w++;
    }}}
    for my $case ([5,5,5,1],[5,5,5,6],[0,0,0,8],[9.5,9.5,9.5,4]) {
        my ($cx,$cy,$cz,$k) = @$case;
        my @got = $s3->query_knn($cx,$cy,$cz,$k);
        is scalar(@got), $k, "3D knn ($cx,$cy,$cz) returns $k";
        my @sorted = sort { d3($p3[$a],$cx,$cy,$cz) <=> d3($p3[$b],$cx,$cy,$cz) } 0..$#p3;
        my %gd; $gd{ sprintf('%.6f', d3($p3[$_],$cx,$cy,$cz)) }++ for @got;
        my %wd; $wd{ sprintf('%.6f', d3($p3[$_],$cx,$cy,$cz)) }++ for @sorted[0..$k-1];
        is_deeply \%gd, \%wd, "3D knn ($cx,$cy,$cz,$k) distances match brute force";
        my @d = map { d3($p3[$_],$cx,$cy,$cz) } @got;
        is_deeply \@d, [sort { $a <=> $b } @d], "3D knn ($cx,$cy,$cz,$k) nearest-first";
    }
}

done_testing;
