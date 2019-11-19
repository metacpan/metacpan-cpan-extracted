#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use_ok('CBOR::Free');

my @nums = (
    1.1,
    -4.1,
    ( map { 100 * rand() - 50 } 1 .. 10 ),
);

for my $i ( @nums ) {
    my $encoded = CBOR::Free::encode($i);

    _cmpbin( $encoded, pack('C d>', 0xfb, $i), "encode $i" );

    # NB: Long-double perls introduce rounding errors when decoding CBOR floats.
    cmp_deeply(
        CBOR::Free::decode($encoded),
        $Config{'uselongdouble'} || $Config{'usequadmath'} ? num($i, 0.0001) : $i,
        "… and it round-trips",
    );
}

{
    my @ints = map { int( rand() * (2**17) - (2**16) ) } 1 .. 20;
    for my $int (@ints) {
        my $cbor = pack('C f>', 0xfa, $int);

        is( CBOR::Free::decode($cbor), $int, "decode int as float: $int" );

        $cbor = pack('C d>', 0xfb, $int);

        is( CBOR::Free::decode($cbor), $int, "decode int as double: $int" );
    }
}

{
    my @ints = map { int( rand() * (2**33) - (2**32) ) } 1 .. 20;
    for my $int (@ints) {
        my $cbor = pack('C d>', 0xfb, $int);

        is( CBOR::Free::decode($cbor), $int, "decode int as double: $int" );
    }
}

my $inf = unpack("f>", "\x7f\x80\x00\x00");
my $nan = unpack("f>", "\x7f\xc0\x00\x00");
my $neginf = unpack("f>", "\xff\x80\x00\x00");

is(
    sprintf('%v.02x', CBOR::Free::encode($inf)),
    'f9.7c.00',
    'Inf encodes to half-precision as expected',
);

TODO: {
    our $TODO = 'Apparently broken on MSWin32 prior to 5.24?' if $^O eq 'MSWin32';

    is(
        sprintf('%v.02x', CBOR::Free::encode($neginf)),
        'f9.fc.00',
        '-Inf encodes to half-precision as expected',
    );
}

is(
    sprintf('%v.02x', CBOR::Free::encode($nan)),
    'f9.7e.00',
    'NaN encodes to half-precision as expected',
);

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

#----------------------------------------------------------------------

done_testing;
