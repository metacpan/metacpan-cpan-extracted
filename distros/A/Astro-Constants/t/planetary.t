use Test::More;
use Astro::Constants::MKS qw/:planetary/;

is(MASS_EARTH, 5.9722e24, 'MASS_EARTH');
is(AXIS_SM_LUNAR, 3.84402e8, 'AXIS_SM_LUNAR');
like(GRAVITY_EARTH, qr/\d/, 'GRAVITY_EARTH');
like(TEMPERATURE_SOLAR_SURFACE, qr/\d/, 'TEMPERATURE_SOLAR_SURFACE');

done_testing();
