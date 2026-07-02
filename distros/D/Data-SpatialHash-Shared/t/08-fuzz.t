use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# Model-based fuzz: maintain a parallel Perl model and assert the module agrees
# after thousands of random insert/move/remove, across radius and knn queries.
# Coordinates and distances are plain IEEE doubles on both sides, so result
# sets must match exactly.

srand(20260621);

my $CS    = 0.7;
my $WORLD = 40;     # coords in [-WORLD, WORLD]
my $MAXR  = 8;      # query radius bound (keeps cells far under the 67M cap)

my $s = Data::SpatialHash::Shared->new(undef, 4000, 0, $CS);
my %pos;            # value => [x,y,z]  (live entries; value is unique)
my %v2h;            # value => handle
my $nextval = 1;

sub rc { (rand() * 2 - 1) * $WORLD }
sub d2 { my ($p,$cx,$cy,$cz) = @_; ($p->[0]-$cx)**2 + ($p->[1]-$cy)**2 + ($p->[2]-$cz)**2 }
sub brute_radius {
    my ($cx,$cy,$cz,$r) = @_; my $r2 = $r*$r;
    return { map { $_ => 1 } grep { d2($pos{$_},$cx,$cy,$cz) <= $r2 } keys %pos };
}

my $ops = 2000;
for my $i (1 .. $ops) {
    my $r = rand();
    if ($r < 0.45 || !%pos) {
        my @p = (rc(), rc(), rc());
        my $v = $nextval++;
        my $h = $s->insert(@p, $v);
        if (defined $h) { $pos{$v} = [@p]; $v2h{$v} = $h; }
    } elsif ($r < 0.65) {
        my ($v) = (keys %pos)[ int(rand(scalar keys %pos)) ];
        $s->remove($v2h{$v});
        delete $pos{$v}; delete $v2h{$v};
    } else {
        my ($v) = (keys %pos)[ int(rand(scalar keys %pos)) ];
        my @p = (rc(), rc(), rc());
        $s->move($v2h{$v}, @p);
        $pos{$v} = [@p];
    }

    next if $i % 40;
    is $s->count, scalar keys %pos, "count matches model (op $i)";
    my ($cx,$cy,$cz,$rr) = (rc(), rc(), rc(), rand()*$MAXR);
    my %got = map { $_ => 1 } $s->query_radius($cx,$cy,$cz,$rr);
    is_deeply \%got, brute_radius($cx,$cy,$cz,$rr), "radius matches model (op $i)"
        or diag "center=($cx,$cy,$cz) r=$rr";
}

# final knn cross-check (distance-multiset, tie-tolerant)
for (1 .. 20) {
    my ($cx,$cy,$cz) = (rc(), rc(), rc());
    my $k    = 1 + int(rand(10));
    my $want = $k < keys %pos ? $k : scalar keys %pos;
    my @got  = $s->query_knn($cx,$cy,$cz,$k);
    is scalar @got, $want, "knn returns min(k,count)";
    my @sorted = sort { d2($pos{$a},$cx,$cy,$cz) <=> d2($pos{$b},$cx,$cy,$cz) } keys %pos;
    my %gd; $gd{ sprintf('%.6f', d2($pos{$_},$cx,$cy,$cz)) }++ for @got;
    my %wd; $wd{ sprintf('%.6f', d2($pos{$_},$cx,$cy,$cz)) }++ for @sorted[0 .. $want-1];
    is_deeply \%gd, \%wd, "knn distances match model";
}

done_testing;
