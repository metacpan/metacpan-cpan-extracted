#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

use Crypt::Rijndael::PP;
use Crypt::Rijndael::PP::Debug qw( generate_printable_state );

use Readonly;
Readonly my $STRING       => "ABCDEFGHIJKLMNOP";
Readonly my $SHORT_STRING => "ABCDE";
Readonly my $LONG_STRING  => "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

subtest "Convert 128 Bit Input to State" => sub {
    my $state;
    lives_ok {
        $state = Crypt::Rijndael::PP->_input_to_state( $STRING );
    } "Lives through conversion";

    if( !defined $state ) {
        return;
    }

    note( generate_printable_state( $state ) );

    for ( my $row_index = 0; $row_index < 4; $row_index++ ) {
        for ( my $column_index = 0; $column_index < 4; $column_index++ ) {

            my $state_byte = unpack( "H2",
                $state->[$row_index][$column_index] );

            my $input_byte = unpack( "x"
                . ( $row_index + ( $column_index * 4 ) )
                . "H2", $STRING );

            cmp_ok( $state_byte, 'eq', $input_byte,
                "Correct State Byte at $row_index x $column_index" );
        }
    }
};

subtest "Convert Less than 128 Bit Input to State" => sub {
    throws_ok {
        Crypt::Rijndael::PP->_input_to_state( $SHORT_STRING );
    } qr/Invalid Input Length, Must be 128 Bits/,
    "Dies with invalid input size";
};

subtest "Convert More than 128 Bit Input to State" => sub {
    throws_ok {
        Crypt::Rijndael::PP->_input_to_state( $LONG_STRING );
    } qr/Invalid Input Length, Must be 128 Bits/,
    "Dies with invalid input size";
};

done_testing;
