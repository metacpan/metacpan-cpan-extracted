use Test::More tests => 2;

BEGIN { use_ok('Alien::UDUNITS2'); }

my $u = Alien::UDUNITS2->new;

like( $u->libs, qr/udunits2\b/, 'libs has correct flag');


done_testing;
