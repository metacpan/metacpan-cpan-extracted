#!/usr/bin/env perl
package MyObj;
use strict;
use warnings;

sub new { bless {}, shift };

package RSAobject;
use strict;
use warnings;

sub new { bless {}, shift };


package InheritanceObject;
use parent 'Crypt::MagicSignatures::Key';
use strict;
use warnings;

sub hello {
  print "Hi World!";
};


package main;
use Test::More;
use strict;
use warnings;
use Test::Output;

my $module = 'Crypt::MagicSignatures::Key';
use_ok($module, qw/b64url_encode b64url_decode/);

ok(my $obj = MyObj->new, 'New object created');

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new($obj);
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);

ok($obj = RSAobject->new, 'New object with RSA prefix');

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new($obj);
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);

# MiniMe-Test
my $encodedPrivateKey = 'RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotO'.
  'bbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmv'.
  'ptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';
ok($obj = InheritanceObject->new($encodedPrivateKey), 'Inheritance object');

is(ref Crypt::MagicSignatures::Key->new($obj), 'InheritanceObject', 'Inheritance is fine');


stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new({ n => 2 });
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new('12345');
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);


stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new('DSA.1234');
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);

# MiniMe-Test (Key - shortened)
$encodedPrivateKey = 'RSA.' . # Missing
  '.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new($encodedPrivateKey);
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid object'
);

# MiniMe-Test (Key - with broken b64)
$encodedPrivateKey = 'RSA.:::::=.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new($encodedPrivateKey);
  },
  qr/Invalid parameters for MagicKey construction/,
  'Invalid b64url string'
);


# MiniMe-Test (Key - with b64 for size 23)
$encodedPrivateKey = 'RSA.' . b64url_encode('AHA') . '.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new($encodedPrivateKey);
  },
  qr/Keysize is out of range/,
  'Size is too small'
);

# MiniMe-Test (Key - with b64 for size 16000)
use utf8;
$encodedPrivateKey = 'RSA.' . b64url_encode('ü' x 1000) . '.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Key->new($encodedPrivateKey), 'No object returned');
  },
  qr/Keysize is out of range/,
  'Size is too big'
);

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new( e => 3, n => 0 );
  },
  qr/Invalid/,
  'Modulus not given'
);

stderr_like(
  sub {
    Crypt::MagicSignatures::Key->new( e => 3, n => Math::BigInt->bnan );
  },
  qr/n is not a number.*invalid/si,
  'Modulus not given'
);

# https://github.com/eschnou/node-ostatus/blob/master/tests/test-salmon.js
my $test_public_key =<<'TEST_PKEY';
RSA.iuv17d7U1uJxgDbCt1nEtaIbKAmV02MWIQLubaW
Dc4juUBmdvbY1ms0EtFhrYLSK1j3kyqysM7vqjj-DYD
bq2NPQpUrq2DFqj7Y2b8PG4-Dj6KUPDmkVRa-ZFo63B
WX6US5Vsi31HHFh_rku1OPdPrHjQhtN8HeFYnNBpd4U
AA0=.AQAB
TEST_PKEY

ok(my $key1 = Crypt::MagicSignatures::Key->new($test_public_key), 'New public key');
ok(my $key2 = Crypt::MagicSignatures::Key->new($key1), 'Old public key based on other');
is($key1, $key2, 'Key was just returned');

# https://github.com/eschnou/node-ostatus/blob/master/tests/test-salmon.js
# Without exponent
$test_public_key =<<'TEST_PKEY';
RSA.iuv17d7U1uJxgDbCt1nEtaIbKAmV02MWIQLubaW
Dc4juUBmdvbY1ms0EtFhrYLSK1j3kyqysM7vqjj-DYD
bq2NPQpUrq2DFqj7Y2b8PG4-Dj6KUPDmkVRa-ZFo63B
WX6US5Vsi31HHFh_rku1OPdPrHjQhtN8HeFYnNBpd4U
AA0=.
TEST_PKEY

is($key1->e, '65537', 'Exponent set');
ok(my $key3 = Crypt::MagicSignatures::Key->new($test_public_key), 'New public key without e');
is($key3->e, '65537', 'Exponent default');

# https://github.com/eschnou/node-ostatus/blob/master/tests/test-salmon.js
# With broken exponent
$test_public_key =<<'TEST_PKEY';
RSA.iuv17d7U1uJxgDbCt1nEtaIbKAmV02MWIQLubaW
Dc4juUBmdvbY1ms0EtFhrYLSK1j3kyqysM7vqjj-DYD
bq2NPQpUrq2DFqj7Y2b8PG4-Dj6KUPDmkVRa-ZFo63B
WX6US5Vsi31HHFh_rku1OPdPrHjQhtN8HeFYnNBpd4U
AA0=.:::::=
TEST_PKEY

ok(my $key4 = Crypt::MagicSignatures::Key->new($test_public_key), 'New public key without e');
is($key4->e, '65537', 'Exponent default');

# Set e to nan:
stderr_like(
  sub {
    ok(!$key4->e(Math::BigInt->bnan), 'Set e to NaN');
  },
  qr/e is not a number/,
  'Set e to NaN'
);

# Set d to nan:
stderr_like(
  sub {
    ok(!$key4->d(Math::BigInt->bnan), 'Set d to NaN');
  },
  qr/d is not a number/,
  'Set d to NaN'
);

no strict 'refs';

# test rsasp1
stderr_like(
  sub {
    *{"${module}::_rsasp1"}->($key3, Math::BigInt->new($key3->n));
  },
  qr/Message representative out of range/,
  'Out of range'
);

stderr_like(
  sub {
    *{"${module}::_rsasp1"}->($key3, Math::BigInt->new($key3->n+1));
  },
  qr/Message representative out of range/,
  'Out of range'
);




done_testing;
__END__
