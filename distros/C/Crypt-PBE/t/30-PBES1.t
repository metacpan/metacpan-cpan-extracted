#!perl

use strict;
use warnings;
use Test::More;

use MIME::Base64;

use_ok('Crypt::PBE::PBES1');

my @args = (
    password   => 'mypassword',
    count      => 1_000,
    hash       => 'md5',
    encryption => 'des',
);

my $pbes1 = new_ok( 'Crypt::PBE::PBES1' => \@args );

my $encrypted = $pbes1->encrypt('secret');

cmp_ok( $pbes1->decrypt($encrypted), 'eq', 'secret' );

done_testing();
