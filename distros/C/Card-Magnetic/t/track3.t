#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;

use_ok( 'Card::Magnetic');

my $stripe = <<EOF;
;240000000000000000^1232343456456756786778901239011223171712345678903456789?
EOF

my $structure = {
        FORMAT_CODE     => 24,
        PAN             => "0000000000000000",
        COUNTRY_CODE    => "123",
        CURRENCY_CODE   => "234",
        AMOUNTAUTH      => "3456",
        AMOUNTREMAINING => "4567",
        CYCLE_BEGIN     => "5678",
        CYCLE_LENGHT    => "67",
        RETRY_COUNT     => "7",
        PINCP           => "890123",
        INTERCHANGE     => "9",
        PANSR           => "01",
        SAN1            => "12",
        SAN2            => "23",
        EXPIRATION_DATE => "1717",
        CARD_SEQUENCE   => "1",
        CARD_SECURITY   => "234567890",
        RELAY_MARKER    => "3",
        CRYPTO_CHECK    => "456789",
};

my $card = Card::Magnetic->new();

$card->stripe( $stripe );

$card->parse();

is_deeply( $card->{ track3 }, $structure, "Stripe Structure" );

print Dumper $card;

done_testing();
