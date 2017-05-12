#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Rijndael::PP;
use Crypt::Rijndael::PP::Debug qw( generate_printable_state );

use Readonly;
Readonly my @CIPHER_KEY => (
    0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
);

Readonly my @ROUND_0_INPUT => (
    0x32, 0x43, 0xf6, 0xa8,
    0x88, 0x5a, 0x30, 0x8d,
    0x31, 0x31, 0x98, 0xa2,
    0xe0, 0x37, 0x07, 0x34,
);

Readonly my @ROUND_0_EXPECTED_OUTPUT => (
    0x19, 0x3d, 0xe3, 0xbe,
    0xa0, 0xf4, 0xe2, 0x2b,
    0x9a, 0xc6, 0x8d, 0x2a,
    0xe9, 0xf8, 0x48, 0x08,
);

Readonly my @ROUND_9_INPUT => (
    0x47, 0x37, 0x94, 0xed,
    0x40, 0xd4, 0xe4, 0xa5,
    0xa3, 0x70, 0x3a, 0xa6,
    0x4c, 0x9f, 0x42, 0xbc,
);

Readonly my @ROUND_9_EXPECTED_OUTPUT => (
    0xeb, 0x40, 0xf2, 0x1e,
    0x59, 0x2e, 0x38, 0x84,
    0x8b, 0xa1, 0x13, 0xe7,
    0x1b, 0xc3, 0x42, 0xd2,
);

# Generate key schedule for usage in the AddRoundKey calculations.
my $key_schedule = Crypt::Rijndael::PP->_ExpandKey( pack( "C16", @CIPHER_KEY ) );

subtest "Round 0 AddRoundKey" => sub {
    my $packed_input = pack( "C*", @ROUND_0_INPUT );
    my $state = Crypt::Rijndael::PP->_input_to_state(
        $packed_input
    );

    note("Original State:\n");
    note( generate_printable_state( $state ) );

    my $packed_expected_ouput = pack( "C*", @ROUND_0_EXPECTED_OUTPUT );
    my $expected_state = Crypt::Rijndael::PP->_input_to_state(
        $packed_expected_ouput
    );

    my $updated_state;
    lives_ok {
        $updated_state = Crypt::Rijndael::PP->_AddRoundKey(
            $state, $key_schedule, 0
        );
    } "Lives through AddRoundKey";

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
                "Correct AddRoundKey State Byte ($state_byte) at $row_index x $column_index" );
        }
    }
};

subtest "Round 9 AddRoundKey" => sub {
    my $packed_input = pack( "C*", @ROUND_9_INPUT );
    my $state = Crypt::Rijndael::PP->_input_to_state(
        $packed_input
    );

    note("Original State:\n");
    note( generate_printable_state( $state ) );

    my $packed_expected_ouput = pack( "C*", @ROUND_9_EXPECTED_OUTPUT );
    my $expected_state = Crypt::Rijndael::PP->_input_to_state(
        $packed_expected_ouput
    );

    my $updated_state;
    lives_ok {
        $updated_state = Crypt::Rijndael::PP->_AddRoundKey(
            $state, $key_schedule, 9
        );
    } "Lives through AddRoundKey";

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
                "Correct AddRoundKey State Byte ($state_byte) at $row_index x $column_index" );
        }
    }
};

done_testing;
