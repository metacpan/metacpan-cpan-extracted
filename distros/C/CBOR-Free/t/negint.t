#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Test::Deep;

use_ok('CBOR::Free');

for my $i ( -24 .. -1 ) {
    _cmpbin( CBOR::Free::encode($i), chr(0x1f - $i), "encode $i" );
}

for my $i ( -25, -256 ) {
    _cmpbin( CBOR::Free::encode($i), "\x38" . chr(-1 - $i), "encode $i" );
}

for my $i ( -257, -65536 ) {
    _cmpbin( CBOR::Free::encode($i), pack('C n', 0x39, -1 - $i), "encode $i" );
}

# -0x80000000 is the minimum negative integer on 32-bit systems.
for my $i ( -65537, -0x80000000 ) {
    _cmpbin( CBOR::Free::encode($i), pack('C N', 0x3a, -1 - $i), "encode $i" );
}

# Do this on non-64-bit perls only:
if ( (0xffffffff << 1) < 0xffffffff ) {
    is(
        CBOR::Free::decode("\x3a\x7f\xff\xff\xff"),
        -2147483648,
        '32-bit Perl: decode biggest allowed negative',
    );

    throws_ok(
        sub { diag explain( CBOR::Free::decode("\x3a\x80\0\0\0") ) },
        'CBOR::Free::X::NegativeIntTooLow',
        '32-bit Perl: out-of-bounds negative int is rejected as expected',
    );

    my $err = $@->get_message();

    cmp_deeply(
        $err,
        all(
            re( qr<2147483649> ),
            re( qr<1> ),
        ),
        '… and the error looks as we expect',
    );
}

SKIP: {
    skip 'No 64-bit support!' if !eval { pack 'q' };

    for my $i ( -0xffffffff, -0xffffffff - 1 ) {
        my $cbor = CBOR::Free::encode($i);
        _cmpbin( $cbor, pack('C N', 0x3a, -1 - $i), "encode $i" );
        is( CBOR::Free::decode($cbor), $i, '… and it round-trips' );
    }

    for my $i ( -0xffffffff - 2, -9223372036854775808 ) {
        my $cbor = CBOR::Free::encode($i);
        _cmpbin( $cbor, pack('C q>', 0x3b, -1 - $i), "encode $i" );
        is( CBOR::Free::decode($cbor), $i, '… and it round-trips' );
    }

    throws_ok(
        sub { diag explain( CBOR::Free::decode("\x3b\x80\0\0\0\0\0\0\0") ) },
        'CBOR::Free::X::NegativeIntTooLow',
        'out-of-bounds negative int is rejected as expected',
    );

    my $err = $@->get_message();

    cmp_deeply(
        $err,
        all(
            re( qr<9223372036854775809> ),
            re( qr<1> ),
        ),
        '… and the error looks as we expect',
    );
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

done_testing;
