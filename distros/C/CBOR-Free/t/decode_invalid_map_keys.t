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

done_testing;
