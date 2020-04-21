use Test::More;
use Astro::Constants::MKS qw/:electromagnetic/;

is(PERMEABL_FREE_SPACE, 1.25663706212e-06, 'PERMEABL_FREE_SPACE');
is(ELECTRON_CHARGE, 1.602176634e-19, 'ELECTRON_CHARGE');
like(PERMITIV_FREE_SPACE, qr/\d/, "PERMITIV_FREE_SPACE");
like(MASS_ELECTRON, qr/\d/, "MASS_ELECTRON");

done_testing();
