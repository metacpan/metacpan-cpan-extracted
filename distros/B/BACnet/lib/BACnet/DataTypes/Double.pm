#!/usr/bin/perl

package BACnet::DataTypes::Double;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 8, };

sub construct {
    my ( $class, $input_double, $modified_tag ) = @_;

    my $self = {
        data => BACnet::DataTypes::Utils::_construct_head(
            BACnet::DataTypes::Utils::DOUBLE_TAG,
            $modified_tag, LENGTH )
          . pack( 'd>', $input_double ),
        val => $input_double,
    };

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::DOUBLE_TAG,
        expected_length => LENGTH,
    );

    if ( !$headache eq '' ) {
        $self->{error} = "Double: $headache";
        return $self;
    }

    $self->{val} = unpack(
        'd>',
        substr(
            $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in),
            LENGTH
        )
    );

    return $self;
}

1;
