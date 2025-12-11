#!/usr/bin/perl

package BACnet::DataTypes::Real;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 0x04 };

sub construct {
    my ( $class, $input_real, $modified_tag ) = @_;

    my $self = {
        data => BACnet::DataTypes::Utils::_construct_head(
            BACnet::DataTypes::Utils::REAL_TAG,
            $modified_tag, LENGTH )
          . pack( 'f>', $input_real ),
        val => $input_real,
    };

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::REAL_TAG,
        expected_length => LENGTH,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Real: $headache";
        return $self;
    }

    $self->{val} = unpack( 'f>',
        substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) )
    );

    return $self;
}

1;
