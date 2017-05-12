use strict;
use warnings;
use Astro::Nova qw/:all/;

# observer location: Karlsruhe, for rst 
my $observer = Astro::Nova::LnLatPosn->new(
  lat => Astro::Nova::DMS->from_string("49°00' N")->to_degrees,
  lng => Astro::Nova::DMS->from_string("8°23' E")->to_degrees,
);

my $now = get_julian_from_sys(); # current julian date

print "Current Julian Day: $now\n";

my $moon_from_earth = get_lunar_geo_posn($now, 0);

my ($moonx, $moony, $moonz) = ($moon_from_earth->get_X, $moon_from_earth->get_Y, $moon_from_earth->get_Z);
printf("Moon is at (%.02fkm, %.02fkm, %.02fkm)\n", $moonx, $moony, $moonz);
printf("Moon distance: %.02fkm\n", get_lunar_earth_dist($now));


my $moon_lnglat = get_lunar_ecl_coords($now, 0);
print "Moon at:\n", $moon_lnglat->as_ascii();

my $moon_equatorial = get_lunar_equ_coords($now);

my $moon_fraction = get_lunar_disk($now);
print "Current moon fraction: $moon_fraction\n";
print "Moon phase " . get_lunar_phase($now) . "\n";

my ($status, $moon_rst) = get_lunar_rst($now, $observer);
if ($status == 1) {
  print "Moon is circumpolar\n";
}
else {
  print "Rise time:\n",    get_local_date( $moon_rst->get_rise() )->as_ascii(), "\n";
  print "Transit time:\n", get_local_date( $moon_rst->get_transit() )->as_ascii(), "\n";
  print "Set time:\n",     get_local_date( $moon_rst->get_set() )->as_ascii(), "\n";
}

