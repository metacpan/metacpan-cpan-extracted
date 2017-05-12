#!/usr/bin/env perl

use Test::More tests => 10;
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

# Reference: https://github.com/diaspora/diaspora/blob/master/lib/salmon/slap.rb
# Reference: http://marchdown.xenoethics.org/src/diaspora/lib/salmon/slap.rb

my $k = Crypt::MagicSignatures::Key->new('data:application/magic-public-key,RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKUEK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww.AQAB');

is($k->e, 65537, 'Proudhon Magickey e');
is($k->n, '8031283789075196565022891546563591368344944062154100509645398892293433370859891943306439907454883747534493461257620351548796452092307094036643522661681091', 'Proudhon Magickey n');
is($k->size, 512, 'Correct key size');


$k = Crypt::MagicSignatures::Key->new('RSA.mVgY8RN6URBTstndvmUUPb4UZTdwvwmddSKE5z_jvKUEK6yk1u3rrC9yN8k6FilGj9K0eeUPe2hf4Pj-5CmHww.AQAB');

is($k->e, 65537, 'Proudhon Magickey e 1');
is($k->n, '8031283789075196565022891546563591368344944062154100509645398892293433370859891943306439907454883747534493461257620351548796452092307094036643522661681091', 'Proudhon Magickey n 2');

ok(!$k->d, 'Private 1');
is($k->size, 512, 'Correct key size');


# http://code.google.com/p/minime-microblogger/source/browse/trunk/tests/classes/magic/signature/signtest.php

$k = Crypt::MagicSignatures::Key->new('RSA.hkwS0EK5Mg1dpwA4shK5FNtHmo9F7sIP6gKJ5fyFWNotObbbckq4dk4dhldMKF42b2FPsci109MF7NsdNYQ0kXd3jNs9VLCHUujxiafVjhw06hFNWBmvptZud7KouRHz4Eq2sB-hM75MEn3IJElOquYzzUHi7Q2AMalJvIkG26c=.AQAB.JrT8YywoBoYVrRGCRcjhsWI2NBUBWfxy68aJilEK-f4ANPdALqPcoLSJC_RTTftBgz6v4pTv2zqiJY9NzuPo5mijN4jJWpCA-3HOr9w8Kf8uLwzMVzNJNWD_cCqS5XjWBwWTObeMexrZTgYqhymbfxxz6Nqxx352oPh4vycnXOk=');

ok($k->d, 'Private 2');
is($k->size, 1024, 'Correct key size');
