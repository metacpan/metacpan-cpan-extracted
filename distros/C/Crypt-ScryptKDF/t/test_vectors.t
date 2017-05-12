use strict;
use warnings;

use Crypt::ScryptKDF;
use Test::More;

### https://tools.ietf.org/html/draft-josefsson-scrypt-kdf-00#page-11
### http://www.tarsnap.com/scrypt/scrypt.pdf

is( Crypt::ScryptKDF::scrypt_hex("", "", 16, 1, 1, 64),
    "77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906" );

is( Crypt::ScryptKDF::scrypt_hex("password", "NaCl", 1024, 8, 16, 64),
    "fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640" );

is( Crypt::ScryptKDF::scrypt_hex("pleaseletmein", "SodiumChloride", 16384, 8, 1, 64),
    "7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887" );

SKIP: {
  #BEWARE: this test is time consuming!!!
  skip 'set SCRYPT_EXTRA_TESTS to enable devel tests', 1 unless $ENV{SCRYPT_EXTRA_TESTS};
  is( Crypt::ScryptKDF::scrypt_hex("pleaseletmein", "SodiumChloride", 1048576, 8, 1, 64),
      "2101cb9b6a511aaeaddbbe09cf70f881ec568d574a2ffd4dabe5ee9820adaa478e56fd8f4ba5d09ffa1c6d927c40f4c337304049e8a952fbcbf45c6fa77a41a4" );
}

done_testing;