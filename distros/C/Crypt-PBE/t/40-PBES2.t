#!perl

use strict;
use warnings;
use Test::More;

use MIME::Base64;

use_ok('Crypt::PBE::PBES2');

my @args = (
    password   => 'mypassword',
    count      => 1_000,
    hmac       => 'hmac-sha256',
    encryption => 'aes-128',
);

my $pbes2 = new_ok( 'Crypt::PBE::PBES2' => \@args );

my $encrypted = $pbes2->encrypt('secret');

cmp_ok( $pbes2->decrypt($encrypted), 'eq', 'secret' );

done_testing();
