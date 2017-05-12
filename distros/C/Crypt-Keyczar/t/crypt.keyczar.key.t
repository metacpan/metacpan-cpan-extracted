use Test::More tests => 3;
use strict;
use warnings;


BEGIN { use_ok('Crypt::Keyczar::Key'); }

my $key = Crypt::Keyczar::Key->generate_key('HMAC_SHA1', 256);
ok(ref $key eq 'Crypt::Keyczar::HmacKey');
ok(length $key->get_bytes == 256/8);
