#!/usr/bin/perl

package BACnet::ServiceRequestSequences::ReadProperty;

use warnings;
use strict;

use bytes;

use BACnet::ServiceRequestSequences::Utils;
use BACnet::DataTypes::Enum;
use BACnet::DataTypes::ObjectIdentifier;
use BACnet::DataTypes::UnsignedInt;
use BACnet::DataTypes::SequenceValue;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Enums::PropertyIdentifier;

our $request_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'object_identifier',
        dt   => 'BACnet::DataTypes::ObjectIdentifier'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'property_identifier',
        dt   => 'BACnet::DataTypes::Enum'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'property_array_index',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    )
];

sub request {
    my %args = (
        object_identifier_type     => undef,
        object_identifier_instance => undef,
        property_identifier        => undef,
        property_array_index       => undef,
        @_,
    );

    my $sequence_elements = [
        [
            'object_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct(
                $args{object_identifier_type},
                $args{object_identifier_instance},
                0x00
            )
        ],
        [
            'property_identifier',
            BACnet::DataTypes::Enum->construct(
                $args{property_identifier}, 0x01
            )
        ],
    ];

    if ( defined $args{property_array_index} ) {
        push @$sequence_elements,
          [
            'property_array_index',
            BACnet::DataTypes::UnsignedInt->construct(
                $args{property_array_index}, 0x02
            )
          ];
    }

    return BACnet::DataTypes::SequenceValue->construct($sequence_elements);
}

our $negative_response_skeleton =
  $BACnet::ServiceRequestSequences::Utils::error_type_skeleton;

sub negative_response {
    return BACnet::ServiceRequestSequences::Utils::_error_type(@_);
}

our $positive_response_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'object_identifier',
        dt   => 'BACnet::DataTypes::ObjectIdentifier'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'property_identifier',
        dt   => 'BACnet::DataTypes::Enum'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'property_array_index',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    ),
    BACnet::DataTypes::Bone->construct(
        tag          => 3,
        name         => 'property_value',
        dt           => 'property_identifier',
        substitution =>
          $BACnet::DataTypes::Enums::PropertyIdentifier::prop_type_type,
    )

];

sub positive_response {
    my %args = (
        object_identifier_type     => undef,
        object_identifier_instance => undef,
        property_identifier        => undef,
        property_array_index       => undef,
        property_value             => undef,
        @_,
    );

    my $sequence_elements = [
        [
            'object_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct(
                $args{object_identifier_type},
                $args{object_identifier_instance},
                0x00
            )
        ],
        [
            'property_identifier',
            BACnet::DataTypes::Enum->construct(
                $args{property_identifier}, 0x01
            )
        ],
    ];

    if ( defined $args{property_array_index} ) {
        push @$sequence_elements,
          [
            'property_array_index',
            BACnet::DataTypes::UnsignedInt->construct(
                $args{property_array_index}, 0x02
            )
          ];
    }

    #have to have context tag 0x03
    push @$sequence_elements, [ 'property_value', $args{property_value}, ];

    return BACnet::DataTypes::SequenceValue->construct($sequence_elements);
}

1;
