use strict;
use warnings;
use Test::More;
use Data::SpatialHash::Shared;

my $PI = 4 * atan2(1, 1);
my $R  = 6371000.0;   # Earth-ish body radius (metres)

sub xyz {   # mirror of the C sph_geo_to_xyz
    my ($lat, $lon, $alt) = @_;
    my $r = $R + $alt;
    return ($r * cos($lat) * cos($lon), $r * cos($lat) * sin($lon), $r * sin($lat));
}

srand(20260622);

# ---- lat/lon/alt round-trips ----
my $s = Data::SpatialHash::Shared->new(undef, 6000, 0, 50000, sphere => $R);
my $rt_ok = 1;
for my $i (1 .. 300) {
    my $lat = (rand() - 0.5) * $PI * 0.98;     # avoid exact poles
    my $lon = (rand() * 2 - 1) * $PI * 0.999;  # avoid exact +-pi
    my $alt = rand() * 100000;
    my $h   = $s->insert_geo($lat, $lon, $alt, $i);
    my @p   = $s->position_geo($h);
    $rt_ok = 0, diag("rt $i: got @p want $lat $lon $alt"), last
        unless abs($p[0] - $lat) < 1e-9 && abs($p[1] - $lon) < 1e-9 && abs($p[2] - $alt) < 1e-3;
}
ok $rt_ok, 'lat/lon/alt round-trip (300 random surface+air points)';
is $s->sphere, $R, 'sphere() returns the body radius';
my $nongeo = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0);
is $nongeo->sphere, 0, 'sphere() is 0 for a non-geo map';

# pole: lat and alt round-trip; lon is undefined there (do not assert it)
my @pp = $s->position_geo($s->insert_geo($PI / 2, 1.7, 500, -1));
ok abs($pp[0] - $PI / 2) < 1e-9, 'north pole latitude round-trips';
ok abs($pp[2] - 500) < 1e-3,     'north pole altitude round-trips';

# +-pi meridian: longitude magnitude round-trips to ~pi
my @pm = $s->position_geo($s->insert_geo(0.3, $PI, 0, -2));
ok abs(abs($pm[1]) - $PI) < 1e-6, '+-pi meridian longitude magnitude round-trips';

# move_geo
my $hmv = $s->insert_geo(0.1, 0.1, 0, -3);
ok $s->move_geo($hmv, 0.2, 0.2, 1000), 'move_geo returns true';
my @mp = $s->position_geo($hmv);
ok abs($mp[0] - 0.2) < 1e-9 && abs($mp[1] - 0.2) < 1e-9 && abs($mp[2] - 1000) < 1e-3, 'move_geo relocated entity';

my $freed = $s->insert_geo(0.1, 0.1, 0, -4);
$s->remove($freed);
ok !$s->move_geo($freed, 0.2, 0.2, 0), 'move_geo returns false for a freed handle';
eval { $s->position_geo($freed) }; like $@, qr/invalid|freed/, 'position_geo croaks on a freed handle';

# ---- query_geo_radius vs brute-force 3D oracle (clustered patch) ----
my $g = Data::SpatialHash::Shared->new(undef, 6000, 0, 50000, sphere => $R);
my @pts;
for my $i (1 .. 500) {
    my @c = (rand() * 0.5, rand() * 0.5, rand() * 20000);   # ~2800km patch
    $g->insert_geo(@c, $i);
    push @pts, [ $i, @c ];
}
my $oracle_ok = 1;
for my $t (1 .. 25) {
    my ($qlat, $qlon, $qalt) = (rand() * 0.5, rand() * 0.5, rand() * 20000);
    my $d = 50000 + rand() * 450000;   # 50km .. 500km
    my @got = sort { $a <=> $b } $g->query_geo_radius($qlat, $qlon, $qalt, $d);
    my @qx  = xyz($qlat, $qlon, $qalt);
    my @want;
    for my $p (@pts) {
        my @px = xyz($p->[1], $p->[2], $p->[3]);
        my $d2 = ($px[0] - $qx[0])**2 + ($px[1] - $qx[1])**2 + ($px[2] - $qx[2])**2;
        push @want, $p->[0] if $d2 <= $d * $d;
    }
    @want = sort { $a <=> $b } @want;
    unless (scalar(@got) == scalar(@want) && "@got" eq "@want") {
        $oracle_ok = 0;
        diag("oracle $t: got ".scalar(@got)." want ".scalar(@want)." (d=".int($d)."m)");
        last;
    }
}
ok $oracle_ok, 'query_geo_radius matches brute-force 3D oracle (25 queries)';

# ---- validation / croaks ----
my $f = Data::SpatialHash::Shared->new(undef, 10, 0, 1.0);   # no sphere => geo disabled
eval { $f->insert_geo(0, 0, 0, 1) };       like $@, qr/sphere/, 'insert_geo croaks without sphere';
eval { $f->move_geo(0, 0, 0, 0) };         like $@, qr/sphere/, 'move_geo croaks without sphere';
eval { $f->position_geo(0) };              like $@, qr/sphere/, 'position_geo croaks without sphere';
eval { $f->query_geo_radius(0, 0, 0, 1) }; like $@, qr/sphere/, 'query_geo_radius croaks without sphere';

eval { $s->query_geo_radius(0, 0, 0, -1) }; like $@, qr/dist/, 'query_geo_radius croaks on negative dist';

eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, sphere => 0) };  like $@, qr/sphere/, 'sphere => 0 croaks';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, sphere => -5) }; like $@, qr/sphere/, 'sphere => -5 croaks';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, sphere => ("NaN" + 0)) }; like $@, qr/sphere/, 'sphere => NaN croaks';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, sphere => ("Inf" + 0)) }; like $@, qr/sphere/, 'sphere => Inf croaks';
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 1.0, sphere => 100, wrap => [4, 4]) }; like $@, qr/mutually exclusive/, 'sphere + wrap croaks (incompatible topologies)';

# ---- sphere_radius persists across reopen ----
my $path = "/tmp/sph-geo-$$.bin";
unlink $path;
{
    my $w = Data::SpatialHash::Shared->new($path, 100, 0, 1000, sphere => 1234.5);
    $w->insert_geo(0.1, 0.2, 0, 7);   # alt 0 -> on the radius-1234.5 sphere
}
{
    my $r = Data::SpatialHash::Shared->new($path, 999, 0, 9999, sphere => 9999);   # caller args ignored; stored header wins
    my @p = $r->position_geo(0);
    ok abs($p[2]) < 1e-3, 'sphere_radius restored on reopen (alt ~ 0, not ~ R)';
    ok abs($p[0] - 0.1) < 1e-9 && abs($p[1] - 0.2) < 1e-9, 'geo position correct after reopen';
    is $r->sphere, 1234.5, 'caller sphere arg ignored on reopen (stored 1234.5 wins)';
}
unlink $path;

# sphere_radius also survives the memfd / new_from_fd path
{
    my $m = Data::SpatialHash::Shared->new_memfd('geo', 100, 0, 1000, sphere => 4321.0);
    $m->insert_geo(0.2, 0.3, 0, 9);
    my $r = Data::SpatialHash::Shared->new_from_fd($m->memfd);
    my @p = $r->position_geo(0);
    ok abs($p[2]) < 1e-3, 'sphere_radius restored via memfd / new_from_fd (alt ~ 0)';
}

done_testing;
