use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 10000, 0, 1.0);
my @pts;  # [x,y,value]
my $v = 0;
for my $x (0..29) { for my $y (0..29) {
    my ($px,$py) = ($x + 0.5, $y + 0.5);
    $s->insert($px, $py, $v);
    push @pts, [$px, $py, $v];
    $v++;
}}

# brute-force radius reference
sub brute_radius { my ($cx,$cy,$r) = @_;
    my %want; for (@pts) { my ($px,$py,$val)=@$_;
        $want{$val}=1 if ($px-$cx)**2 + ($py-$cy)**2 <= $r*$r; } return \%want; }

for my $case ([15,15,3.0],[0,0,2.0],[29,29,5.0],[10,20,0.4]) {
    my ($cx,$cy,$r) = @$case;
    my %got = map { $_ => 1 } $s->query_radius($cx,$cy,$r);
    is_deeply \%got, brute_radius($cx,$cy,$r), "radius ($cx,$cy,$r)";
}

# aabb
my %abox = map { $_ => 1 } $s->query_aabb(5, 5, 8, 8);  # inclusive box
my %wbox; for (@pts) { my ($px,$py,$val)=@$_;
    $wbox{$val}=1 if $px>=5 && $px<=8 && $py>=5 && $py<=8; }
is_deeply \%abox, \%wbox, 'aabb 2D';

# single cell
my @cell = $s->query_cell(15.2, 15.9);   # cell (15,15) -> the point (15.5,15.5)
is scalar(@cell), 1, 'one point in cell';

# 3D radius
my $t = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
$t->insert(0,0,0, 1); $t->insert(0,0,2, 2); $t->insert(3,0,0, 3);
my %r3 = map { $_=>1 } $t->query_radius(0,0,0, 2.0);
is_deeply \%r3, {1=>1, 2=>1}, '3D radius excludes far point';

# 3D aabb brute-force cross-check
my $a3 = Data::SpatialHash::Shared->new(undef, 5000, 0, 1.0);
my @p3; my $vv = 0;
for my $x (0..9) { for my $y (0..9) { for my $z (0..9) {
    $a3->insert($x+0.5, $y+0.5, $z+0.5, $vv); push @p3, [$x+0.5, $y+0.5, $z+0.5, $vv]; $vv++;
}}}
my %ab3 = map { $_ => 1 } $a3->query_aabb(2,2,2, 6,6,6);
my %wb3; for (@p3) { my ($px,$py,$pz,$val) = @$_;
    $wb3{$val} = 1 if $px>=2 && $px<=6 && $py>=2 && $py<=6 && $pz>=2 && $pz<=6; }
is_deeply \%ab3, \%wb3, 'aabb 3D matches brute force';

# defensive cap: an absurd radius vs cell_size croaks instead of wedging
my $cap = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
$cap->insert(0, 0, 1);
eval { $cap->query_radius(0, 0, 1e9) };
like $@, qr/cell/i, 'huge radius croaks (defensive cap)';
eval { $cap->query_aabb(-1e9, -1e9, 1e9, 1e9) };
like $@, qr/cell/i, 'huge aabb croaks (defensive cap)';
# a normal large-ish query well under the cap still works
my @ok = $cap->query_radius(0, 0, 50);   # ~100x100 cells, far under cap
is scalar(@ok), 1, 'normal query under the cap still returns results';

done_testing;
