#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Rijndael::PP::GF qw( gf_multiply );

use Readonly;
Readonly my $GF_MULTIPLICATION_TEST_VALUES => {
    0x02 => { 0x12 => 0x24,  0xa2 => 0x5f,  0xf6 => 0xf7, },
    0x03 => { 0x12 => 0x36,  0xa2 => 0xfd,  0xf6 => 0x01, },
    0x09 => { 0x12 => 0x82,  0xa2 => 0xc5,  0xf6 => 0x07, },
    0x0b => { 0x12 => 0xa6,  0xa2 => 0x9a,  0xf6 => 0xf0, },
    0x0d => { 0x12 => 0xca,  0xa2 => 0x7b,  0xf6 => 0xf2, },
    0x0e => { 0x12 => 0xfc,  0xa2 => 0x86,  0xf6 => 0xf3, },
};

subtest "Attempt to gf_multiply a left_factor that has not been precomputed" => sub {
    throws_ok {
        gf_multiply( 0xFF, 0x00 );
    } qr/Left Factor not precomputed/, "Croaks on left factor not precomputed";
};

subtest "gf_multiply gives correct value" => sub {
    for my $left_factor ( keys %{ $GF_MULTIPLICATION_TEST_VALUES } ) {
        subtest "Left Factor - 0x" . unpack("x3H2", pack("N", $left_factor ) ) => sub {
            for my $right_factor ( keys %{ $GF_MULTIPLICATION_TEST_VALUES->{ $left_factor } } ) {

                my $product;
                lives_ok {
                    $product = gf_multiply($left_factor, $right_factor);
                } "Lives through gf_multiply";

                cmp_ok( $product, '==', $GF_MULTIPLICATION_TEST_VALUES->{$left_factor}{$right_factor},
                    "Correct Value for 0x" . unpack("x3H2", pack("N", $right_factor ) ) );
            }
        };
    }
};

done_testing;
