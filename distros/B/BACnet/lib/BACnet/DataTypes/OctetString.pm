#!/usr/bin/perl

package BACnet::DataTypes::OctetString;

use warnings;
use strict;

use bytes;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

sub construct {
    my ( $class, $input_octet_string, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_octet_string,
    };

    # Context Tag doc. page 378

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::OCTET_STRING_TAG,
        $modified_tag, length($input_octet_string) );

    $self->{data} .= $input_octet_string;

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $head = unpack( 'C', $data_in );

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::OCTET_STRING_TAG,
    );

    if ( $headache ne "" ) {
        $self->{error} = "OctetString: $headache";
        return $self;
    }

    $self->{val} = substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) );

    return $self;
}

1;
