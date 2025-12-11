#!/usr/bin/perl

package BACnet::ServiceRequestSequences::Utils;

use warnings;
use strict;

require BACnet::DataTypes::SequenceValue;
require BACnet::DataTypes::Enum;

require BACnet::DataTypes::Bone;

our $error_type_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'error_class',
        dt   => 'BACnet::DataTypes::Enum'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'error_code',
        dt   => 'BACnet::DataTypes::Enum'
    ),
];

sub _error_type {
    my %args = (
        error_class => undef,
        error_code  => undef,
        @_,
    );

    return BACnet::DataTypes::SequenceValue->construct(
        [
            [
                'error_class',
                BACnet::DataTypes::Enum->construct( $args{error_class}, 0x00 )
            ],
            [
                'error_code',
                BACnet::DataTypes::Enum->construct( $args{error_code}, 0x01 )
            ]
        ],
    );
}

1;
