use strict;
use warnings;
use Test::More;
use Data::SpatialHash::Shared;

# cube_* methods are stateless; any map provides them
my $s = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0);

srand(20260622);
sub rdir {   # uniform-ish nonzero direction
    my @d;
    do { @d = (rand() * 2 - 1, rand() * 2 - 1, rand() * 2 - 1) }
        while ($d[0]**2 + $d[1]**2 + $d[2]**2 < 1e-6);
    return @d;
}

# ---- partition: each direction -> exactly one cell that reports its level ----
for my $lvl (0, 2, 5) {
    my (%seen, $bad);
    for (1 .. 4000) {
        my $c = $s->cube_cell(rdir(), $lvl);
        $seen{$c}++;
        $bad++ unless $s->cube_level($c) == $lvl;
    }
    is $bad, undef, "level $lvl: every cell reports level $lvl";
    cmp_ok scalar(keys %seen), '<=', 6 * (4 ** $lvl), "level $lvl: distinct cells <= 6*4^$lvl";
}
my %faces;
$faces{ $s->cube_cell(rdir(), 0) }++ for 1 .. 3000;
is scalar(keys %faces), 6, 'all 6 cube faces reachable at level 0';

# ---- round-trip: cube_cell(cube_center(id), level) == id ----
my $rt = 1;
for my $lvl (0, 1, 4, 10, 20, 24) {
    for (1 .. 1500) {
        my $c   = $s->cube_cell(rdir(), $lvl);
        my @ctr = $s->cube_center($c);
        next if $s->cube_cell(@ctr, $lvl) == $c;
        $rt = 0;
        diag("round-trip failed at level $lvl: $c");
        last;
    }
    last unless $rt;
}
ok $rt, 'cube_cell(cube_center(id), level) == id across all faces, levels 0..24';

my @u = $s->cube_center($s->cube_cell(0.3, -0.5, 0.8, 12));
ok abs(sqrt($u[0]**2 + $u[1]**2 + $u[2]**2) - 1.0) < 1e-12, 'cube_center returns a unit vector';

# cube_cell_geo == cube_cell on the equivalent unit direction
my $geo_ok = 1;
for (1 .. 300) {
    my $lat = (rand() - 0.5) * 3.0;
    my $lon = (rand() * 2 - 1) * 3.1;
    my @d = (cos($lat) * cos($lon), cos($lat) * sin($lon), sin($lat));
    $geo_ok = 0, last unless $s->cube_cell_geo($lat, $lon, 14) == $s->cube_cell(@d, 14);
}
ok $geo_ok, 'cube_cell_geo matches cube_cell on the equivalent unit direction';

# cube_center_geo agrees with cube_center
my $cc = $s->cube_cell_geo(0.4, 1.1, 9);
my @g  = $s->cube_center_geo($cc);
my @x  = $s->cube_center($cc);
my @gx = (cos($g[0]) * cos($g[1]), cos($g[0]) * sin($g[1]), sin($g[0]));
ok abs($gx[0]-$x[0]) < 1e-9 && abs($gx[1]-$x[1]) < 1e-9 && abs($gx[2]-$x[2]) < 1e-9,
    'cube_center_geo agrees with cube_center';

# ---- hierarchy ----
my $hok = 1;
for my $lvl (0, 3, 10, 23) {
    for (1 .. 500) {
        my $c = $s->cube_cell(rdir(), $lvl);
        my @kids = $s->cube_children($c);
        $hok = 0, last unless @kids == 4;
        my %distinct = map { $_ => 1 } @kids;
        $hok = 0, last unless keys(%distinct) == 4;
        for my $k (@kids) {
            $hok = 0 unless $s->cube_parent($k) == $c && $s->cube_level($k) == $lvl + 1;
        }
        last unless $hok;
    }
    last unless $hok;
}
ok $hok, 'children: 4 distinct, each parent==self and level+1 (levels 0..23)';
is_deeply [ $s->cube_children($s->cube_cell(1, 0, 0, 24)) ], [], 'no children at MAX_LEVEL';
ok !defined($s->cube_parent($s->cube_cell(1, 0, 0, 0))), 'no parent at level 0';

# ---- validation ----
eval { $s->cube_cell(1, 0, 0, -1) };          like $@, qr/level/, 'cube_cell rejects negative level';
eval { $s->cube_cell(1, 0, 0, 25) };          like $@, qr/level/, 'cube_cell rejects level > 24';
eval { $s->cube_center(~0) };                 like $@, qr/valid/, 'cube_center rejects stray high bits';
eval { $s->cube_parent(31 << 51) };           like $@, qr/valid/, 'cube_parent rejects bad level field (31 > 24)';
eval { $s->cube_cell_geo(0, 0, -1) };         like $@, qr/level/, 'cube_cell_geo rejects negative level';
eval { $s->cube_cell_geo(0, 0, 25) };         like $@, qr/level/, 'cube_cell_geo rejects level > 24';
eval { $s->cube_center_geo(~0) };             like $@, qr/valid/, 'cube_center_geo rejects malformed id';
eval { $s->cube_level(~0) };                  like $@, qr/valid/, 'cube_level rejects malformed id';
eval { $s->cube_children(~0) };               like $@, qr/valid/, 'cube_children rejects malformed id';
ok $s->cube_level($s->cube_cell(0, 0, 0, 5)) == 5, 'cube_cell on the zero vector returns a valid cell (no crash)';

# ---- neighbors (seam-aware, perturb-and-reproject) ----
my $PI = 4 * atan2(1, 1);
sub gcdist {   # great-circle angle between two unit vectors
    my ($a, $b) = @_;
    my $dot = $a->[0]*$b->[0] + $a->[1]*$b->[1] + $a->[2]*$b->[2];
    $dot = 1 if $dot > 1; $dot = -1 if $dot < -1;
    return atan2(sqrt(1 - $dot*$dot), $dot);
}
my ($n_distinct, $n_adj, $n_recip) = (1, 1, 1);
for my $lvl (0, 1, 3, 6, 10) {
    my $w = $PI / (2 * 2 ** $lvl);          # ~angular cell width
    for (1 .. 1200) {
        my $c  = $s->cube_cell(rdir(), $lvl);
        my @nb = $s->cube_neighbors($c);
        my %uniq = map { $_ => 1 } @nb;
        $n_distinct = 0
            unless @nb == 4 && keys(%uniq) == 4 && !grep { $_ == $c } @nb;
        my @cc = $s->cube_center($c);
        for my $n (@nb) {
            my @nc = $s->cube_center($n);
            $n_adj = 0 if gcdist(\@cc, \@nc) > 4 * $w + 1e-9;
            $n_recip = 0 unless grep { $_ == $c } $s->cube_neighbors($n);
        }
    }
}
ok $n_distinct, 'cube_neighbors: 4 distinct cells, none equal to self (levels 0..10)';
ok $n_adj,      'cube_neighbors: each neighbour centre within a few cell-widths (seam transform sane)';
ok $n_recip,    'cube_neighbors: reciprocal across all seams (a in nbr(b) <=> b in nbr(a))';

# connectivity: BFS over neighbors must reach every cell at a coarse level
for my $lvl (1, 2) {
    my $total = 6 * 4 ** $lvl;
    my $start = $s->cube_cell(1, 0, 0, $lvl);
    my %seen  = ($start => 1);
    my @q     = ($start);
    while (@q) {
        my $c = shift @q;
        for my $n ($s->cube_neighbors($c)) { next if $seen{$n}; $seen{$n} = 1; push @q, $n; }
    }
    is scalar(keys %seen), $total, "level $lvl: BFS over neighbors reaches all $total cells";
}

eval { $s->cube_neighbors(~0) }; like $@, qr/valid/, 'cube_neighbors rejects malformed id';

done_testing;
