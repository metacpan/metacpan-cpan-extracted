#!/usr/bin/perl

package BACnet::DataTypes::CharString;

use warnings;
use strict;

use bytes;
use Encode;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { CODE_SEGMENT_LENGTH => 1, };

our $codes = {
    'ascii'       => 0x00,
    'shiftjis'    => 0x01,
    'jis0208-raw' => 0x02,
    'UTF-32'      => 0x03,
    'UCS-2BE'     => 0x04,
    'iso-8859-1'  => 0x05,
};

our $codes_rev = { reverse %$codes };

sub construct {
    my ( $class, $input_char_string, $coding_type, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_char_string,
    };

    my $encoded_val = encode( $coding_type, $input_char_string );

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::CHARACTER_STRING_TAG,
        $modified_tag, length($encoded_val) + CODE_SEGMENT_LENGTH );

    $self->{data} .= pack( 'C', $codes->{$coding_type} );

    $self->{data} .= $encoded_val;

    my $helper = $self->{val};

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in      => $data_in,
        expected_tag => BACnet::DataTypes::Utils::CHARACTER_STRING_TAG
    );

    if ( $headache ne "" ) {
        $self->{error} = "Char string: $headache";
        return $self;
    }

    my $helper = BACnet::DataTypes::Utils::_get_head_length($data_in);

    my $coding_type_num = unpack(
        'C',
        substr(
            $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in), 1
        )
    );

    my $coding_type = $codes_rev->{$coding_type_num};

    if ( !defined $coding_type ) {
        $self->{error} = "Char string: undefined coding type";
        return $self;
    }

    $self->{val} = decode(
        $coding_type,
        substr(
            $data_in,
            BACnet::DataTypes::Utils::_get_head_length($data_in) +
              CODE_SEGMENT_LENGTH
        )
    );

    return $self;
}

sub coding_type {
    my ($self) = @_;

    return
      $codes_rev->{ BACnet::DataTypes::Utils::_get_char_string_coding_type(
            $self->{data} ) };
}

1;
