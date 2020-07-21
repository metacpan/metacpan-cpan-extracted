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

my %params = (
    password => 'password',
    salt     => 'salt',
    count    => 1_000
);

cmp_ok(
    Crypt::PBE::PBKDF1::pbkdf1_sha1_base64(%params),
    'eq',
    'So/UjkJu0IG1Nb5XaYkvo5YpPvs=',
    'PBKDF1 with SHA1 in Base64'
);

cmp_ok( Crypt::PBE::PBKDF1::pbkdf1_md5_base64(%params), 'eq', 'hHXGqFMaXSfjhs1JZFeBLA==', 'PBKDF1 with MD5 in Base64' );

cmp_ok( Crypt::PBE::PBKDF1::pbkdf1_md2_base64(%params), 'eq', '2gKWHr1EhMMfQOqB7sFK/w==', 'PBKDF1 with MD2 in Base64' );

done_testing();
