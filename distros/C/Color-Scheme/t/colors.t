#!perl
use strict;
use warnings;

use Test::More;
use Color::Scheme;

use t::lib::ColorTest;

{
    my $c     = Color::Scheme->new->from_hex('ff9900')->distance(0.5);
    my %tests = (
        mono => [
            qw(
                ff9900 b36b00 ffe6bf ffcc80
                )
        ],
        contrast => [
            qw(
                ff9900 b36b00 ffe6bf ffcc80
                0040ff 002db3 bfcfff 809fff
                )
        ],
        triade => [
            qw(
                ff9900 b36b00 ffe6bf ffcc80
                00ffff 00b3b3 bfffff 80ffff
                5500ff 3c00b3 d5bfff aa80ff
                )
        ],
        tetrade => [
            qw(
                ff9900 b36b00 ffe6bf ffcc80
                0040ff 002db3 bfcfff 809fff
                6b00ff 4b00b3 dabfff b580ff
                ffe500 b3a000 fff9bf fff280
                )
        ],
        analogic => [
            qw(
                ff9900 b36b00 ffe6bf ffcc80
                ffcc00 b38f00 fff2bf ffe680
                ff6600 b34700 ffd9bf ffb380
                )
        ],
    );

    while ( my ( $scheme, $colors ) = each %tests ) {
        color_test(
            [ $c->scheme($scheme)->colors ],
            $colors,
            "$scheme scheme",
        );
    }
}

done_testing;
