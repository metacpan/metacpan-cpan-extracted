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
    0x7a, 0x9f, 0x10, 0x27,
    0x89, 0xd5, 0xf5, 0x0b,
    0x2b, 0xef, 0xfd, 0x9f,
    0x3d, 0xca, 0x4e, 0xa7,
);

Readonly my @EXPECTED_OUTPUT => (
    0xbd, 0x6e, 0x7c, 0x3d,
    0xf2, 0xb5, 0x77, 0x9e,
    0x0b, 0x61, 0x21, 0x6e,
    0x8b, 0x10, 0xb6, 0x89,
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
        $updated_state = Crypt::Rijndael::PP->_InvSubBytes( $state );
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
