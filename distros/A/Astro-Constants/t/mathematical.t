use Test::More;
use Astro::Constants::MKS qw/:mathematical/;

like(PI, qr/3\.14159/, 'PI');
like(EXP, qr/2\./, 'e');

done_testing();
