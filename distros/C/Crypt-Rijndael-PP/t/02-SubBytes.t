#!/usr/bin/env perl

use strict;
use warnings;
use bytes;

use Data::Dumper;
use Test::Exception;
use Test::More;

use Crypt::Rijndael::PP;
use Crypt::Rijndael::PP::Debug qw( generate_printable_state );

use Readonly;
Readonly my @INPUT => (
    0x19, 0x3d, 0xe3, 0xbe,
    0xa0, 0xf4, 0xe2, 0x2b,
    0x9a, 0xc6, 0x8d, 0x2a,
    0xe9, 0xf8, 0x48, 0x08,
);

Readonly my @EXPECTED_OUTPUT => (
    0xd4, 0x27, 0x11, 0xae,
    0xe0, 0xbf, 0x98, 0xf1,
    0xb8, 0xb4, 0x5d, 0xe5,
    0x1e, 0x41, 0x52, 0x30,
);

subtest "Perform SubBytes on Input State" => sub {
    my $packed_input = pack( "C*", @INPUT );
    my $state = Crypt::Rijndael::PP->_input_to_state( $packed_input );

    note("Original State:\n");
    note( generate_printable_state( $state ) );

    my $packed_expected_output = pack( "C*", @EXPECTED_OUTPUT );
    my $expected_state = Crypt::Rijndael::PP->_input_to_state(
        $packed_expected_output
    );

    my $updated_state;
    lives_ok {
        $updated_state = Crypt::Rijndael::PP->_SubBytes( $state );
    } "Lives through SubBytes";

    note("Updated State:\n");
    note( generate_printable_state( $updated_state ) );

    note("Expected State:\n");
    note( generate_printable_state( $expected_state ) );

    my $byte_index = 0;
    for ( my $row_index = 0; $row_index < 4; $row_index++ ) {
        for ( my $column_index = 0; $column_index < 4; $column_index++ ) {

            my $state_byte = unpack( "H2",
                $updated_state->[$row_index][$column_index]
            );

            my $expected_state_byte = unpack( "H2",
                $expected_state->[$row_index][$column_index]
            );

            cmp_ok( $state_byte, 'eq', $expected_state_byte,
                "Correct SubByte State Byte at $row_index x $column_index" );
        }
    }
};

done_testing;
