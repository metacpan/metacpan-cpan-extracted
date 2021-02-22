#!perl

use strict;
use warnings;
use Test::More;

use_ok('Crypt::PBE::PBKDF1');

my @args = (
    password   => 'mypassword',
    algorithm  => 'sha1',
    iterations => 1000,
    salt       => 'mysalt',
);

my $pbkdf1 = new_ok( 'Crypt::PBE::PBKDF1' => \@args );

cmp_ok( $pbkdf1->derived_key_base64, 'eq', 'dGKN9gssD71wS6+Zz6tL4yJtBcw=',             'Bse64 DK' );
cmp_ok( $pbkdf1->derived_key_hex,    'eq', '74628df60b2c0fbd704baf99cfab4be3226d05cc', 'HEX DK' );

done_testing();
