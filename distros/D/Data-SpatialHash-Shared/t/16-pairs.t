use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

srand(20260622);
sub key { my ($a,$b) = @_; $a < $b ? "$a-$b" : "$b-$a" }

# --- per-entry radius accessors ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my $h = $s->insert(1, 2, 99);
    is $s->get_radius($h), 0, 'default radius is 0';
    $s->set_radius($h, 7.5);
    is $s->get_radius($h), 7.5, 'set_radius / get_radius round-trip';
    my $h3 = $s->insert(1, 2, 3, 888, 2.5);          # 3D insert with radius (items 6)
    is $s->get_radius($h3), 2.5, 'insert(x,y,z,value,radius) stores radius';
    eval { $s->get_radius(9999) }; ok $@, 'get_radius on bad handle croaks';
    $s->remove($h);
    eval { $s->set_radius($h, 1) }; ok $@, 'set_radius on freed handle croaks';
    eval { $s->get_radius($h) };    ok $@, 'get_radius on freed handle croaks';
}
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    is $s->get_radius($s->insert(1, 2, 3, 77)), 0, 'plain 3D insert defaults radius 0';
}
{   # set_radius actually gates collision discovery
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    my $ga = $s->insert(0, 0, 1); my $gb = $s->insert(5, 0, 2);   # 5 apart, radius 0
    my $n0 = 0; $s->each_colliding_pair(sub { $n0++ });
    is $n0, 0, 'no collisions while radii are 0';
    $s->set_radius($ga, 3); $s->set_radius($gb, 3);               # sum 6 > distance 5
    my $n1 = 0; $s->each_colliding_pair(sub { $n1++ });
    is $n1, 1, 'set_radius makes the pair collide';
}

# --- each_pair_within vs brute force (Euclidean) ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);
    my @p; my $v = 0;
    for (1..250) { my @xy = (rand()*40, rand()*40); $s->insert(@xy, $v); push @p, [@xy, $v]; $v++; }
    my $maxr = 3;
    my %got; $s->each_pair_within($maxr, sub { $got{ key($_[0], $_[1]) }++ });
    my %want;
    for my $i (0..$#p) { for my $j ($i+1..$#p) {
        my $dx = $p[$i][0]-$p[$j][0]; my $dy = $p[$i][1]-$p[$j][1];
        $want{ key($p[$i][2], $p[$j][2]) } = 1 if $dx*$dx + $dy*$dy < $maxr*$maxr;
    }}
    is_deeply { map { $_ => 1 } keys %got }, \%want, 'each_pair_within matches brute force';
    ok !(grep { $_ > 1 } values %got), 'each pair emitted exactly once';

    # max_r == 0 is documented-valid: fires zero callbacks without croaking
    my $n0 = 0; eval { $s->each_pair_within(0, sub { $n0++ }) };
    is $@, '', 'each_pair_within(0) does not croak (0 is a valid max_r)';
    is $n0, 0, 'each_pair_within(0) fires zero callbacks';
}

# --- each_colliding_pair vs brute force (heterogeneous radii) ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 2.0);   # small cell vs big radii
    my @q; my $v = 0;
    for (1..250) {
        my @xy = (rand()*40, rand()*40); my $r = 0.5 + rand()*6;
        my $h = $s->insert(@xy, $v); $s->set_radius($h, $r);
        push @q, [@xy, $v, $r]; $v++;
    }
    my %got; $s->each_colliding_pair(sub { $got{ key($_[0], $_[1]) }++ });
    my %want;
    for my $i (0..$#q) { for my $j ($i+1..$#q) {
        my $dx = $q[$i][0]-$q[$j][0]; my $dy = $q[$i][1]-$q[$j][1];
        $want{ key($q[$i][2], $q[$j][2]) } = 1 if sqrt($dx*$dx + $dy*$dy) < $q[$i][3] + $q[$j][3];
    }}
    is_deeply { map { $_ => 1 } keys %got }, \%want, 'each_colliding_pair matches brute force';
    ok !(grep { $_ > 1 } values %got), 'each colliding pair emitted exactly once';
}

# --- 3D pairs (z != 0): enumeration must cover the real z-cells, not just z=0 ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 2.0);
    my @p; my $v = 0;
    for (1..200) { my @xyz = (rand()*30, rand()*30, rand()*30); $s->insert(@xyz, $v); push @p, [@xyz, $v]; $v++; }
    my $maxr = 4;
    my %got; $s->each_pair_within($maxr, sub { $got{ key($_[0], $_[1]) }++ });
    my %want;
    for my $i (0..$#p) { for my $j ($i+1..$#p) {
        my $dx = $p[$i][0]-$p[$j][0]; my $dy = $p[$i][1]-$p[$j][1]; my $dz = $p[$i][2]-$p[$j][2];
        $want{ key($p[$i][3], $p[$j][3]) } = 1 if $dx*$dx + $dy*$dy + $dz*$dz < $maxr*$maxr;
    }}
    is_deeply { map { $_ => 1 } keys %got }, \%want, '3D each_pair_within matches brute force (z != 0)';

    # collision mode in 3D too
    my $c = Data::SpatialHash::Shared->new(undef, 1000, 0, 2.0);
    my @q; $v = 0;
    for (1..200) { my @xyz = (rand()*30, rand()*30, rand()*30); my $r = 0.5+rand()*5;
        my $h = $c->insert(@xyz, $v); $c->set_radius($h, $r); push @q, [@xyz, $v, $r]; $v++; }
    my %gc; $c->each_colliding_pair(sub { $gc{ key($_[0], $_[1]) }++ });
    my %wc;
    for my $i (0..$#q) { for my $j ($i+1..$#q) {
        my $dx = $q[$i][0]-$q[$j][0]; my $dy = $q[$i][1]-$q[$j][1]; my $dz = $q[$i][2]-$q[$j][2];
        $wc{ key($q[$i][3], $q[$j][3]) } = 1 if sqrt($dx*$dx+$dy*$dy+$dz*$dz) < $q[$i][4]+$q[$j][4];
    }}
    is_deeply { map { $_ => 1 } keys %gc }, \%wc, '3D each_colliding_pair matches brute force';
}

# --- toroidal each_pair_within: seam pairs must be found ---
{
    sub td  { my ($a,$b,$w) = @_; my $d = abs($a-$b); ($w > 0 && $d > $w/2) ? $w-$d : $d }
    my $W = 60;
    my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 4.0, wrap => [$W, $W]);
    my @p; my $v = 0;
    for (1..200) { my @xy = (rand()*$W, rand()*$W); $s->insert(@xy, $v); push @p, [@xy, $v]; $v++; }
    my $maxr = 5;
    my %got; $s->each_pair_within($maxr, sub { $got{ key($_[0], $_[1]) }++ });
    my %want;
    for my $i (0..$#p) { for my $j ($i+1..$#p) {
        my $dx = td($p[$i][0],$p[$j][0],$W); my $dy = td($p[$i][1],$p[$j][1],$W);
        $want{ key($p[$i][2], $p[$j][2]) } = 1 if $dx*$dx + $dy*$dy < $maxr*$maxr;
    }}
    is_deeply { map { $_ => 1 } keys %got }, \%want, 'toroidal each_pair_within matches brute force';
}

# --- callback may die / is invoked under no lock ---
{
    my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
    $s->insert(1, 1, 1); $s->insert(1.5, 1, 2);
    eval { $s->each_pair_within(2, sub { die "stop\n" }) };
    like $@, qr/stop/, 'dying pair callback propagates';
    ok defined($s->insert(0, 0, 3)), 'map usable after dying pair callback (lock not stranded)';
}

done_testing;
