use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use Alien::ngtcp2;

alien_ok 'Alien::ngtcp2';

like(
    Alien::ngtcp2->version,
    qr/^\d+\.\d+(?:\.\d+)?/,
    'ngtcp2 version is available',
);

ok(
    length(Alien::ngtcp2->libs),
    'linker flags are available',
);

done_testing;
