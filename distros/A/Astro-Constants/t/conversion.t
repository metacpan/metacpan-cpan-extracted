use Test::More;
use Astro::Constants::MKS qw/:conversion/;

is(ATOMIC_MASS_UNIT, 1.660_539_040e-27, 'ATOMIC_MASS_UNIT');
is(AVOGADRO, 6.022_140_857e23, 'AVOGADRO');
unlike(BOLTZMANN, qr/\d/, "Shouldn't import BOLTZMANN with :conversion");
unlike(MASS_ELECTRON, qr/\d/, "Shouldn't import MASS_ELECTRON with :conversion");

done_testing();
