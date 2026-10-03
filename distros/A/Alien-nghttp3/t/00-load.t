use strict;
use warnings;

use Test2::V0;
use Alien::nghttp3;

ok(
    Alien::nghttp3->isa('Alien::Base'),
    'Alien::nghttp3 loads as an Alien::Base subclass',
);

done_testing;
