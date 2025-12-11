#!/usr/bin/perl

package BACnet::DataTypes::Int;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

sub construct {
    my ( $class, $input_int, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_int,
    };

    # Context Tag doc. page 378

    my ( $len_in_octets, $encoded_int ) =
      BACnet::DataTypes::Utils::_encode_int($input_int);

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::SIGNED_INT_TAG,
        $modified_tag, $len_in_octets );

    $self->{data} .= $encoded_int;

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;
    my $head = unpack( 'C', substr( $data_in, 0, 1 ) );

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in      => $data_in,
        expected_tag => BACnet::DataTypes::Utils::SIGNED_INT_TAG,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Signed Int: $headache";
        return $self;
    }

    $self->{val} =
      BACnet::DataTypes::Utils::_decode_int(
        substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) )
      );

    return $self;
}

1;
