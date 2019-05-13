#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use_ok('CBOR::Free');

my @invalid = (
    [ "\xf4" => 'false' ],
    [ "\xf5" => 'true' ],
    [ "\xf6" => 'null' ],
    [ "\xf7" => 'undefined' ],
    [ "\x80" => 'array' ],
    [ "\xa0" => 'map' ],
);

for my $t (@invalid) {
    my ($cbor, $what) = @$t;

    $cbor = "\xa2\x04\x08$cbor\x45hello";

    throws_ok(
        sub { CBOR::Free::decode($cbor) },
        qr<$what>,
        "error on decode CBOR $what",
    );

    my $msg = $@->get_message();

    like( $msg, qr<3>, '… and the offset is given' );
}

{
    my $cbor = join(
        q<>,
        "\xa7",

        "\x40\x00",             # q<> => 0

        "\x04\x08",             # 4 => 8
        "\x24\x20",             # -5 => -1

        "\x43abc\x00",          # abc => 0
        "\x5f\x43def\xff\x01",  # def => 1

        "\x63ghi\x00",          # abc => 0
        "\x7f\x63jkl\xff\x01",  # def => 1
    );

    my $got = CBOR::Free::decode($cbor);

    is_deeply(
        $got,
        {
            4 => 8,
            '-5' => -1,
            q<> => 0,
            abc => 0, def => 1,
            ghi => 0, jkl => 1,
        },
        'valid map keys',
    ) or diag explain $got;
}

done_testing;
