#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;

use_ok( 'Card::Magnetic');

my $stripe = <<EOF;
%A0000000000000000^RECSKY^171700012345888?
EOF

my $structure = {
        FORMAT_CODE     => "A",
        PAN             => "0000000000000000",
        NAME            => "RECSKY",
        EXPIRATION_DATE => "1717",
        SERVICE_CODE    => "000",
        PVV             => "12345",
        CVV             => "888",
};

my $card = Card::Magnetic->new();

$card->stripe( $stripe );

$card->parse();

is_deeply( $card->{ track1 }, $structure, "Stripe Structure" );

print Dumper $card;

done_testing();
