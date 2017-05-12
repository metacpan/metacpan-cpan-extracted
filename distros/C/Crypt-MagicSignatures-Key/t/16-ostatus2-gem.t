#!/usr/bin/env perl
use Test::More;
use Math::BigInt try => 'GMP,Pari';
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

our $module;
BEGIN {
    our $module = 'Crypt::MagicSignatures::Key';
    use_ok($module, qw/b64url_encode b64url_decode/);   # 1
};

#########################################
# From OStatus2 gem used in Mastodon    #
# https://github.com/tootsuite/ostatus2 #

my $mkey = 'data:application/magic-public-key,RSA.AKfeoEM7t8a5nBIudEnCZ37cXBw-QgijUmO3JGDFY0OJKrlwtMlUn9-7_dMpYQx_ehSIo1HrFfnVY4YLKQVfpwc.AQAB';

ok($mkey = Crypt::MagicSignatures::Key->new($mkey), 'Get private key');

is($mkey->n, '8792046075689043363232416638565141340544360030419271972383556104721760666810289531879428170641142438262522893048913367584534393199599425777885589146674951',
   "OStatus Modulus");
is($mkey->_emLen, 64, 'OStatus2 k');
ok(!$mkey->d, 'Is a public key');

is(b64url_decode('SGVsbG8gd29ybGQsIEkgYW0gZG9vbSwgYnJpbmdlciBvZiBiYWQgQmFz'.
                   'ZTY0IGFuZCBiaWcgbnVtYmVycyBsaWtlIDk5OTI4ODg3MjM2NzY3ODI4Mg'),
   'Hello world, I am doom, bringer of bad Base64 and big numbers like 999288872367678282',
   'Decoding is fine');

is(b64url_decode(b64url_encode('Hello world')), 'Hello world', 'b64url');

done_testing;
__END__
