#!/usr/bin/env perl

package t::incomplete;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Test::Exception;

use parent qw( Test::Class::Tiny );

use Config;

use Data::Dumper;

use CBOR::Free;
use CBOR::Free::Decoder;
use CBOR::Free::SequenceDecoder;

__PACKAGE__->new()->runtests() if !caller;

use constant INCOMPLETE_TESTS => (
    [
        'empty indefinite array',
        "\x9f",
    ],
    [
        'indefinite array that contains incomplete item',
        "\x9f\x5a",
    ],
    [
        'unended indefinite array',
        "\x9f\x40",
    ],
    [
        'incomplete array length',
        "\x9a",
    ],
    [
        'incomplete string in indefinite-length string',
        "\x5f\x41",
    ],
    [
        'map key is incomplete negative integer',
        "\xa1\x3a",
    ],
    [
        'map key is incomplete string',
        "\xa1\x5a",
    ],
    [
        'map value is indefinite-length string; value is incomplete',
        "\xa1\x5f\x43abc\xff\x5a",
    ],
    [
        'incomplete indefinite-length map',
        "\xbf",
    ],
    [
        'indefinite-length map contains incomplete entry',
        "\xbf\x5a",
    ],
    [
        'map of incomplete length',
        "\xba",
    ],
);

sub runtests {
    my $self = shift;

    $self->num_method_tests( T_incompletes => 3 * INCOMPLETE_TESTS() );

    return $self->SUPER::runtests();
}

sub T_incompletes {
    my $dec = CBOR::Free::Decoder->new();
    my $seqdec = CBOR::Free::SequenceDecoder->new();

    for my $tt (INCOMPLETE_TESTS()) {
        throws_ok(
            sub { CBOR::Free::decode( $tt->[1] ) },
            'CBOR::Free::X::Incomplete',
            "CBOR::Free::decode(): $tt->[0]",
        );

        throws_ok(
            sub { $dec->decode( $tt->[1] ) },
            'CBOR::Free::X::Incomplete',
            "\$decoder->decode(): $tt->[0]",
        );

        is_deeply(
            [ $seqdec->give( $tt->[1] ) ],
            [ undef ],
            "sequence decoder: $tt->[0]",
        );
    }
}

#sub T0_config {
#    my $encoded = CBOR::Free::encode( \%Config );
#
#    my $decoder = CBOR::Free::Decoder->new();
#
#    for my $shortfall ( 1 .. ( length($encoded) - 1 ) ) {
#        my $short = substr( $encoded, 0, -$shortfall );
#
#        throws_ok(
#            sub { CBOR::Free::decode( $short ) },
#            'CBOR::Free::X::Incomplete',
#            "decode() when CBOR is $shortfall byte(s) incomplete",
#        );
#
#        throws_ok(
#            sub { $decoder->decode( $short ) },
#            'CBOR::Free::X::Incomplete',
#            "decode() method when CBOR is $shortfall byte(s) incomplete",
#        );
#
#        my $seqdecoder = CBOR::Free::SequenceDecoder->new();
#
#        is_deeply(
#            [ $seqdecoder->give($short) ],
#            [ undef ],
#            "sequence decoder when CBOR is $shortfall byte(s) incomplete",
#        );
#    }
#}

1;
