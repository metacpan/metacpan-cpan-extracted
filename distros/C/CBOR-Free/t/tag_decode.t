#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use CBOR::Free;
use CBOR::Free::Decoder;

for ( 1 .. 100 ) {
    my $tag = int rand 0xffffffff;

    my $decoder = CBOR::Free::Decoder->new()->set_tag_handlers(
        $tag => sub { 42 + shift() },
    );

    my $cbor = CBOR::Free::encode(
        CBOR::Free::tag( $tag, 123 ),
    );

    my $decoded = $decoder->decode( $cbor );
    is( $decoded, 165, "single callback OK (tag $tag)" );
}

my $decoder = CBOR::Free::Decoder->new()->set_tag_handlers(
    1 => sub { 42 + shift() },
);

my @w;
my $decoded = do {
    local $SIG{'__WARN__'} = sub { push @w, @_ };
    $decoder->decode( "\xcb\x80" );
};

cmp_deeply(
    \@w,
    [ all(
        re(qr<11>),         # tag number
        re(qr<4>),          # major type
        re( qr<array> ),    # major type label
    ) ],
    'warning about unrecognized tag',
);

is_deeply($decoded, [], '… and the value is correct' );

done_testing();
