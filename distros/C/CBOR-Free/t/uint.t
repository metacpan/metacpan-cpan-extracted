#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use_ok('CBOR::Free');

for my $i ( 0 .. 23 ) {
    _cmpbin( CBOR::Free::encode($i), chr($i), "encode $i" );
}

for my $i ( 24, 255 ) {
    _cmpbin( CBOR::Free::encode($i), "\x18" . chr($i), "encode $i" );
}

for my $i ( 256, 65535 ) {
    _cmpbin( CBOR::Free::encode($i), pack('C n', 0x19, $i), "encode $i" );
}

for my $i ( 65536, 0xffffffff ) {
    _cmpbin( CBOR::Free::encode($i), pack('C N', 0x1a, $i), "encode $i" );
}

if (8 == length pack 'L!') {
    for my $i ( 1 + 0xffffffff, 0 + ~0 ) {
        _cmpbin( CBOR::Free::encode($i), pack('C Q>', 0x1b, $i), "encode $i" );
    }
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

done_testing;
