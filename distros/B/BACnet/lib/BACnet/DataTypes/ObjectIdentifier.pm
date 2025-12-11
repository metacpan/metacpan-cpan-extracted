#!/usr/bin/perl

package BACnet::DataTypes::ObjectIdentifier;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 0x04 };

# std-page 421, std: 12
our $obj_types = {
    'Accumulator'        => 23,
    'Analog-Input'       => 0,
    'Analog-Output'      => 1,
    'Analog-Value'       => 2,
    'Averaging'          => 18,
    'Binary-Input'       => 3,
    'Binary-Output'      => 4,
    'Binary-Value'       => 5,
    'Calendar'           => 6,
    'Command'            => 7,
    'Device'             => 8,
    'Event-Enrollment'   => 9,
    'File'               => 10,
    'Group'              => 11,
    'Life-Safety-Point'  => 21,
    'Life-Safety-Zone'   => 22,
    'Loop'               => 12,
    'Multi-State-Input'  => 13,
    'Multi-State-Output' => 14,
    'Multi-State-Value'  => 19,
    'Notification-Class' => 15,
    'Program'            => 16,
    'Pulse-Converter'    => 24,
    'Schedule'           => 17,
    'Trend-Log'          => 20,
};

our $obj_types_rev = { reverse %$obj_types };

sub construct {
    my ( $class, $obj_type, $obj_inst, $modified_tag ) = @_;

    my $self = {
        data            => '',
        object_type     => $obj_type,
        object_instance => $obj_inst,
    };

    # Context Tag

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::OBJECT_ID_TAG,
        $modified_tag, LENGTH );

    $self->{data} .=
      pack( 'N', ( ( $obj_type << 22 ) | ( $obj_inst & 0x3fffff ) ) );

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::OBJECT_ID_TAG,
        expected_length => LENGTH,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Object Identifier: $headache";
        return $self;
    }

    my $data = unpack( 'N',
        substr( $data_in, BACnet::DataTypes::Utils::_get_head_length($data_in) )
    );

    $self->{object_type} = $data >> 22;

    if ( !defined $self->{object_type} ) {
        $self->{error} = "Object Identifier: undefined object identifier";
        return $self;
    }

    $self->{object_instance} = $data & 0x3fffff;

    return $self;
}

sub instance {
    my ($self) = @_;

    return $self->{object_instance};
}

sub type {
    my ($self) = @_;

    return $self->{object_type};
}

sub val {
    my ($self) = @_;

    return [ $self->{object_type}, $self->{object_instance} ];
}

1;
