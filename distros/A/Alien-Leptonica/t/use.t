use Test::More;

use_ok('Alien::Leptonica');

my $u = Alien::Leptonica->new;

like( $u->libs, qr/lept/ );

done_testing;
