use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# Force maximal hash collisions: num_buckets=1 jams every distinct cell into the
# single bucket, so the sph_cell_eq dedup guard does all the work of separating
# cells within a chain. Results must stay exact.

sub d2 { my ($p,$cx,$cy) = @_; ($p->[0]-$cx)**2 + ($p->[1]-$cy)**2 }

for my $nb (1, 2) {
    my $s = Data::SpatialHash::Shared->new(undef, 2000, $nb, 1.0);
    is $s->num_buckets, $nb, "num_buckets forced to $nb";
    my @pts; my $v = 0;
    for my $x (0..19) { for my $y (0..19) {
        $s->insert($x+0.5, $y+0.5, $v); push @pts, [$x+0.5, $y+0.5, $v]; $v++;
    }}
    ok $s->stats->{max_chain} >= 200, "nb=$nb: heavy chaining (max_chain=" . $s->stats->{max_chain} . ")";

    for my $case ([10,10,3],[0,0,5],[19.5,19.5,4]) {
        my ($cx,$cy,$r) = @$case; my $r2 = $r*$r;
        my %got  = map { $_ => 1 } $s->query_radius($cx,$cy,$r);
        my %want = map { $pts[$_][2] => 1 } grep { d2($pts[$_],$cx,$cy) <= $r2 } 0..$#pts;
        is_deeply \%got, \%want, "nb=$nb radius ($cx,$cy,$r) exact under forced collision";

        my @cell = $s->query_cell($cx, $cy);
        my @wc = grep { int($pts[$_][0]) == int($cx) && int($pts[$_][1]) == int($cy) } 0..$#pts;
        is scalar(@cell), scalar(@wc), "nb=$nb cell ($cx,$cy) exact under collision";

        my $k = 6;
        my @sorted = sort { d2($pts[$a],$cx,$cy) <=> d2($pts[$b],$cx,$cy) } 0..$#pts;
        my @gk = $s->query_knn($cx,$cy,$k);
        my %gd; $gd{ sprintf('%.6f', d2($pts[$_],$cx,$cy)) }++ for @gk;
        my %wd; $wd{ sprintf('%.6f', d2($pts[$_],$cx,$cy)) }++ for @sorted[0 .. $k-1];
        is_deeply \%gd, \%wd, "nb=$nb knn ($cx,$cy,$k) exact under collision";
    }
}

done_testing;
