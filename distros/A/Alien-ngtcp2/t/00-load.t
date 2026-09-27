use strict;
use warnings;

use Test2::V0;
use Alien::ngtcp2;

ok(
    Alien::ngtcp2->isa('Alien::Base'),
    'Alien::ngtcp2 loads as an Alien::Base subclass',
);

done_testing;
