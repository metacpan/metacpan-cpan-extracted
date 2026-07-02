use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# Toroidal (wrapping) world: queries use the minimum-image distance and the
# neighbour search wraps across the grid seam. Cross-checked against a
# brute-force toroidal oracle.

sub td  { my ($a,$b,$w) = @_; my $d = abs($a-$b); ($w > 0 && $d > $w/2) ? $w-$d : $d }
sub td2 { my ($pa,$pb,$wx,$wy) = @_; my $dx=td($pa->[0],$pb->[0],$wx); my $dy=td($pa->[1],$pb->[1],$wy); $dx*$dx+$dy*$dy }

my $W = 100;
my $s = Data::SpatialHash::Shared->new(undef, 4000, 0, 5.0, wrap => [$W, $W]);
is_deeply [$s->world], [100, 100], 'world() returns the wrap extents';

my @pts; my $v = 0;
for (my $x = 2.5; $x < $W; $x += 5) {
    for (my $y = 2.5; $y < $W; $y += 5) { $s->insert($x, $y, $v); push @pts, [$x, $y, $v]; $v++; }
}

# explicit seam adjacency: (2.5,52.5) and (97.5,52.5) are toroidal-distance 5 apart
{
    my %near = map { $_ => 1 } $s->query_radius(0, 52.5, 4);
    ok $near{ (grep { $pts[$_][0]==2.5  && $pts[$_][1]==52.5 } 0..$#pts)[0] }, 'finds point just past x=0';
    ok $near{ (grep { $pts[$_][0]==97.5 && $pts[$_][1]==52.5 } 0..$#pts)[0] }, 'finds wrap-around point near x=W';
}

# brute-force radius at seam and interior centres
for my $case ([1,1,4],[99,1,4],[50,50,9],[0,50,6],[99,99,7]) {
    my ($cx,$cy,$r) = @$case; my $r2 = $r*$r;
    my %got  = map { $_ => 1 } $s->query_radius($cx, $cy, $r);
    my %want = map { $pts[$_][2] => 1 } grep { td2([$cx,$cy],$pts[$_],$W,$W) <= $r2 } 0..$#pts;
    is_deeply \%got, \%want, "toroidal radius ($cx,$cy,$r)";
}

# brute-force knn (the wrap path is a bounded linear scan)
for my $case ([1,1],[99,99],[50,3]) {
    my ($cx,$cy) = @$case; my $k = 6;
    my @gk = $s->query_knn($cx, $cy, $k);
    my @sorted = sort { td2([$cx,$cy],$pts[$a],$W,$W) <=> td2([$cx,$cy],$pts[$b],$W,$W) } 0..$#pts;
    my %gd; $gd{ sprintf('%.6f', td2([$cx,$cy],$pts[$_],$W,$W)) }++ for @gk;
    my %wd; $wd{ sprintf('%.6f', td2([$cx,$cy],$pts[$_],$W,$W)) }++ for @sorted[0 .. $k-1];
    is_deeply \%gd, \%wd, "toroidal knn ($cx,$cy)";
}

# each_in_radius wraps too
{
    my @cb; $s->each_in_radius(0, 50, 6, sub { push @cb, $_[0] });
    my %want = map { $pts[$_][2] => 1 } grep { td2([0,50],$pts[$_],$W,$W) <= 36 } 0..$#pts;
    is_deeply { map { $_ => 1 } @cb }, \%want, 'toroidal each_in_radius';
}

# wrap config survives a reopen (file-backed)
{
    my $path = "/tmp/sph-wrap-$$.bin";
    { my $w = Data::SpatialHash::Shared->new($path, 100, 0, 4.0, wrap => [200, 300]); $w->insert(1,1,7); $w->sync; }
    my $w2 = Data::SpatialHash::Shared->new($path, 100, 0, 4.0);
    is_deeply [$w2->world], [200, 300], 'wrap extents persist across reopen';
    $w2->unlink;
}

# 3D toroidal: wrap on all three axes, brute-force radius + knn + pairs
{
    my @Wxyz = (40, 50, 60);
    sub td3 { my ($pa,$pb) = @_; my $s = 0;
        for my $i (0..2) { my $d = td($pa->[$i], $pb->[$i], $Wxyz[$i]); $s += $d*$d } $s }
    my $s3 = Data::SpatialHash::Shared->new(undef, 3000, 0, 5.0, wrap => \@Wxyz);  # 40,50,60 all /5
    is_deeply [$s3->world], \@Wxyz, '3D world() extents';
    my @p; my $v = 0;
    for (1..300) { my @xyz = (rand()*$Wxyz[0], rand()*$Wxyz[1], rand()*$Wxyz[2]);
        $s3->insert(@xyz, $v); push @p, [@xyz, $v]; $v++; }

    for my $case ([1,1,1,8],[39,49,59,7]) {                 # radius at seam corners
        my ($cx,$cy,$cz,$r) = @$case; my $r2 = $r*$r;
        my %got  = map { $_ => 1 } $s3->query_radius($cx,$cy,$cz,$r);
        my %want = map { $p[$_][3] => 1 } grep { td3([$cx,$cy,$cz],$p[$_]) <= $r2 } 0..$#p;
        is_deeply \%got, \%want, "3D toroidal radius ($cx,$cy,$cz,$r)";
    }
    {                                                        # knn
        my ($cx,$cy,$cz,$k) = (1,1,1,6);
        my @gk = $s3->query_knn($cx,$cy,$cz,$k);
        my @sorted = sort { td3([$cx,$cy,$cz],$p[$a]) <=> td3([$cx,$cy,$cz],$p[$b]) } 0..$#p;
        my %gd; $gd{ sprintf('%.6f', td3([$cx,$cy,$cz],$p[$_])) }++ for @gk;
        my %wd; $wd{ sprintf('%.6f', td3([$cx,$cy,$cz],$p[$_])) }++ for @sorted[0 .. $k-1];
        is_deeply \%gd, \%wd, '3D toroidal knn';
    }
    {                                                        # pairs
        my $maxr = 5;
        my %got; $s3->each_pair_within($maxr, sub { my ($a,$b) = @_;
            $got{ $a < $b ? "$a-$b" : "$b-$a" }++ });
        my %want;
        for my $i (0..$#p) { for my $j ($i+1..$#p) {
            my ($a,$b) = ($p[$i][3], $p[$j][3]);
            $want{ $a < $b ? "$a-$b" : "$b-$a" } = 1 if td3($p[$i],$p[$j]) < $maxr*$maxr;
        }}
        is_deeply { map { $_ => 1 } keys %got }, \%want, '3D toroidal each_pair_within';
    }
}

done_testing;
