#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;

use_ok( 'Card::Magnetic');

my $stripe = <<EOF;
;0000000000000000^171700012345888?
EOF

my $structure = {
        PAN             => "0000000000000000",
        EXPIRATION_DATE => "1717",
        SERVICE_CODE    => "000",
        PVV             => "12345",
        CVV             => "888",
};

my $card = Card::Magnetic->new();

$card->stripe( $stripe );

$card->parse();

is_deeply( $card->{ track2 }, $structure, "Stripe Structure" );

done_testing();
