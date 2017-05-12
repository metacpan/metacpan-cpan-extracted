#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Exception;
use Test::More;

use Storable qw( dclone );

use Crypt::Rijndael::PP;
use Crypt::Rijndael::PP::Debug qw( generate_printable_state );

use Readonly;
Readonly my @INPUT => (
    0xbd, 0x6e, 0x7c, 0x3d,
    0xf2, 0xb5, 0x77, 0x9e,
    0x0b, 0x61, 0x21, 0x6e,
    0x8b, 0x10, 0xb6, 0x89,
);

Readonly my @EXPECTED_OUTPUT => (
    0x47, 0x73, 0xb9, 0x1f,
    0xf7, 0x2f, 0x35, 0x43,
    0x61, 0xcb, 0x01, 0x8e,
    0xa1, 0xe6, 0xcf, 0x2c,
);

Readonly my @COLUMN       => ( 0xbd, 0x6e, 0x7c, 0x3d );
Readonly my @MIXED_COLUMN => ( 0x47, 0x73, 0xb9, 0x1f );

subtest "Inverse Mix Individual Column" => sub {
    my $initial_column = [
        $COLUMN[0],
        $COLUMN[1],
        $COLUMN[2],
        $COLUMN[3],
    ];

    my $mixed_column;
    lives_ok {
        $mixed_column = Crypt::Rijndael::PP->_inv_mix_column( $initial_column );
    } "Lives through inverse column mixing";

    is_deeply( $mixed_column, [
        pack( "C", $MIXED_COLUMN[0] ),
        pack( "C", $MIXED_COLUMN[1] ),
        pack( "C", $MIXED_COLUMN[2] ),
        pack( "C", $MIXED_COLUMN[3] ),
    ], "Correct Resultant Column" );
};

subtest "Perform Inverse Mix Columns on Input State" => sub {
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
        $updated_state = Crypt::Rijndael::PP->_InvMixColumns( $state );
    } "Lives through ShiftRows";

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
