#!perl

use strict;
use warnings;
use Test::More;

use_ok('Crypt::PBE::PBKDF2');

# RFC 6070 (https://tools.ietf.org/html/rfc6070)
# PKCS #5: Password-Based Key Derivation Function 2 (PBKDF2) - Test Vectors

my @tests = (
    [ 'password', 'salt', 1,        20, '0c60c80f961f0e71f3a9b524af6012062fe037a6' ],
    [ 'password', 'salt', 2,        20, 'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957' ],
    [ 'password', 'salt', 4096,     20, '4b007901b765489abead49d926f721d065a429c1' ],
    [ 'password', 'salt', 16777216, 20, 'eefe3d61cd4da4e4e9945b3d6ba2158c2634e984', 1 ],    # Very long test
    [
        'passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt',
        4096, 25, '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038'
    ],
    [ "pass\0word", "sa\0lt", 4096, 16, '56fa6aa75548099dcc37d7f03425e0c3' ],
);

my $i = 0;

for (@tests) {

    my ( $password, $salt, $count, $dk_len, $expected, $skip ) = @{$_};

    $i++;

    next if ($skip);

    cmp_ok( pbkdf2_hex( password => $password, salt => $salt, count => $count, dk_len => $dk_len ),
        'eq', $expected, "PBKDF2 Test Vector n.$i (P=$password, S=$salt, c=$count, dkLen=$dk_len)" );

}

done_testing();
