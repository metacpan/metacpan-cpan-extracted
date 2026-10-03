use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use version ();
use Alien::nghttp3;

alien_ok 'Alien::nghttp3';

like(
    Alien::nghttp3->version,
    qr/^\d+\.\d+(?:\.\d+)?/,
    'nghttp3 version is available',
);

ok(
    version->parse(Alien::nghttp3->version) >= version->parse('1.18.0'),
    'nghttp3 is new enough',
);

ok(
    length(Alien::nghttp3->libs),
    'linker flags are available',
);

done_testing;
