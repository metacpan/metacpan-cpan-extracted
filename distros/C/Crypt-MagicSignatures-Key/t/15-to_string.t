#!/usr/bin/env perl
package main;
use Test::More;
use strict;
use warnings;

use_ok('Crypt::MagicSignatures::Key', qw/b64url_encode b64url_decode/);

# MiniMe-Test (Key)
my $encodedPrivateKey = 'RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotO'.
  'bbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmv'.
  'ptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB.JrT8YywoB'.
  'oYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9N'.
  'zuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxx'.
  'z6Nqxx352oPh4vycnXOk=';

ok(my $mkey = Crypt::MagicSignatures::Key->new($encodedPrivateKey), 'Created key');

my $rendered = $mkey->to_string;

is($rendered, 'RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotObbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmvptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB', 'Correct output');

ok($mkey->d, 'Is private key');

is($encodedPrivateKey, $mkey->to_string(1), 'Rendering identical');

ok(my $pubkey = Crypt::MagicSignatures::Key->new($rendered), 'Create pubkey');

ok(!$pubkey->d, 'No public key');
is($rendered, $pubkey->to_string, 'Rendering identical');
is($rendered, $pubkey->to_string(1), 'Rendering identical');


done_testing;
__END__
