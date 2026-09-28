use strict;
use warnings;

use Test2::V0;
use Alien::ngtcp2;

is(
    Alien::ngtcp2->crypto_backend,
    'picotls',
    'Picotls is the TLS backend',
);

is(
    Alien::ngtcp2->crypto_package,
    'libngtcp2_crypto_picotls',
    'Picotls ngtcp2 helper is selected',
);

ok(
    length(Alien::ngtcp2->crypto_cflags),
    'crypto compiler flags are available',
);

ok(
    length(Alien::ngtcp2->crypto_libs),
    'crypto linker flags are available',
);

done_testing;
