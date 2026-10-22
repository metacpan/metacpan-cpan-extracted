use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::KDTree::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
srand(27182);

sub distance2 {
    my ($a, $b) = @_;
    my $s = 0;
    $s += ($a->[$_] - $b->[$_]) ** 2 for 0 .. $#$a;
    return $s;
}

for my $dims (1 .. 16) {
    for my $shape ('random', 'duplicates', 'ordered') {
        my @points = map {
            my $i = $_;
            [map { $shape eq 'ordered' ? $i + $_ / 4 :
                   $shape eq 'duplicates' ? int(rand(4)) - 2 : rand(20) - 10 } 1 .. $dims]
        } 0 .. 127;
        my $path = "$dir/$dims-$shape.kd";
        my $kd = Data::KDTree::Shared->new($path, $dims, 140);
        $kd->add($points[$_], $_) for 0 .. $#points;
        for my $readonly (0, 1) {
            if ($readonly) {
                $kd->freeze;
                $kd = Data::KDTree::Shared->new_readonly($path);
            }
            my $bad = 0;
            for my $trial (1 .. 12) {
                my $q = $trial % 3 ? [map { rand(20) - 10 } 1 .. $dims] : $points[$trial];
                my @d2 = map { distance2($q, $_) } @points;
                my @order = sort { $d2[$a] <=> $d2[$b] } 0 .. $#points;
                my $near = $kd->nearest($q);
                $bad++ if abs($near->{dist} - sqrt($d2[$order[0]])) > 1e-10;
                my $m = (0, 1, 8, 140)[$trial % 4];
                my @knn = $kd->knn($q, $m);
                $bad++ if @knn != ($m < @points ? $m : scalar @points);
                for (0 .. $#knn) {
                    $bad++ if abs($knn[$_]{dist} - sqrt($d2[$order[$_]])) > 1e-10;
                }
                my $r = $trial % 3 ? rand(20) : sqrt($d2[$trial]);
                my @got = sort { $a <=> $b } map { $_->{id} } $kd->radius($q, $r);
                my @want = grep { $d2[$_] <= $r * $r } 0 .. $#points;
                $bad++ unless "@got" eq "@want";
                my @lo = map { rand(20) - 10 } 1 .. $dims;
                my @hi = map { $lo[$_] + rand(10) } 0 .. $#lo;
                @got = sort { $a <=> $b } $kd->range(\@lo, \@hi);
                @want = grep {
                    my $p = $points[$_];
                    my $inside = 1;
                    for (0 .. $#lo) {
                        $inside = 0 if $p->[$_] < $lo[$_] || $p->[$_] > $hi[$_];
                    }
                    $inside
                } 0 .. $#points;
                $bad++ unless "@got" eq "@want";
            }
            is $bad, 0, "brute-force queries: dims=$dims shape=$shape readonly=$readonly";
        }
    }
}

done_testing;
