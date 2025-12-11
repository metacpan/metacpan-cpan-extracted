#!/usr/bin/perl

package BACnet::DataTypes::BitString;

use warnings;
use strict;

use bytes;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

sub construct {
    my ( $class, $input_bit_string, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_bit_string,
    };

    # Context Tag doc. page 378

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::BIT_STRING_TAG,
        $modified_tag,
        BACnet::DataTypes::Utils::_upper_bound_division(
            length($input_bit_string), 8 ) + 1
    );

    if ( ( length($input_bit_string) % 8 ) == 0 ) {    #unused bits
        $self->{data} .= pack( 'C', 0 );
    }
    else {
        $self->{data} .=
          pack( 'C', 8 - ( length($input_bit_string) % 8 ) );
    }

    $self->{data} .= pack( 'B*', $input_bit_string );

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    #my ( $head, $unused_bits, $untrimmed_val ) = unpack( "C C B*", $data_in );

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in      => $data_in,
        expected_tag => BACnet::DataTypes::Utils::BIT_STRING_TAG
    );

    if ( $headache ne "" ) {
        $self->{error} = "Bit string: $headache";
        return $self;
    }

    my ( $unused_bits, $untrimmed_val ) = unpack(
        'C B*',
        substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) )
    );

    $self->{val} =
      substr( $untrimmed_val, 0, length($untrimmed_val) - $unused_bits );

    return $self;
}

1;
