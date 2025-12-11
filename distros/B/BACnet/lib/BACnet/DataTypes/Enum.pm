#!/usr/bin/perl

package BACnet::DataTypes::Enum;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

sub construct {
    my ( $class, $input_enum, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_enum,
    };

    # Context Tag doc. page 378

    my ( $len_in_octets, $encoded_body ) =
      BACnet::DataTypes::Utils::_encode_nonnegative_int($input_enum);

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::ENUMERATED_TAG,
        $modified_tag, $len_in_octets );

    $self->{data} .= $encoded_body;

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in      => $data_in,
        expected_tag => BACnet::DataTypes::Utils::ENUMERATED_TAG,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Enum: $headache";
        return $self;
    }

    $self->{val} =
      BACnet::DataTypes::Utils::_decode_nonnegative_int(
        substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) )
      );

    return $self;
}

1;
