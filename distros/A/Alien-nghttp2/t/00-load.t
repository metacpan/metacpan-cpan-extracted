use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('Alien::nghttp2') }

diag "Alien::nghttp2 version: " . Alien::nghttp2->VERSION;
diag "Install type: " . Alien::nghttp2->install_type;
diag "cflags: " . Alien::nghttp2->cflags;
diag "libs: " . Alien::nghttp2->libs;

ok(Alien::nghttp2->cflags =~ /nghttp2/ || Alien::nghttp2->install_type eq 'system',
   'cflags contains nghttp2 or is system install');

ok(Alien::nghttp2->libs =~ /nghttp2/,
   'libs contains nghttp2');

like(Alien::nghttp2->install_type, qr/^(system|share)$/,
   'install_type is system or share');
