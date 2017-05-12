use Test::More;

use_ok('Alien::LibMagic');

my $u = Alien::LibMagic->new;

like( $u->libs, qr/magic/ );

done_testing;
