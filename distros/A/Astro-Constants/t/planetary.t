use Test::More;
use Astro::Constants::MKS qw/:planetary/;

is(EARTH_MASS, 5.9722e24, 'EARTH_MASS');
is(LUNAR_SM_AXIS, 3.844e8, 'LUNAR_SM_AXIS');
like(EARTH_GRAVITY, qr/\d/, 'EARTH_GRAVITY');
like(SOLAR_TEMPERATURE, qr/\d/, 'SOLAR_TEMPERATURE');

done_testing();
