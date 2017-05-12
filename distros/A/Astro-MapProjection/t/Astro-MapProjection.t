use strict;
use warnings;
use Test::More tests => 7;
use Astro::MapProjection;
pass();

# TODO: .... test for real?

my ($lat, $long) = (1,1);
my ($x, $y) = Astro::MapProjection::hammer_projection($lat, $long);
ok(defined $x);
ok(defined $y);

($x, $y) = Astro::MapProjection::miller_projection($lat, $long);
ok(defined $x);
ok(defined $y);

($x, $y) = Astro::MapProjection::sinusoidal_projection($lat, $long);
ok(defined $x);
ok(defined $y);

