#!/usr/bin/perl

package BACnet::ServiceRequestSequences::COVUnconfirmedNotification;

use warnings;
use strict;

use BACnet::ServiceRequestSequences::Utils;
use BACnet::DataTypes::Enums::PropertyIdentifier;

sub request {
    my %args = (
        subscriber_process_identifier         => undef,
        initiating_device_identifier_type     => undef,
        initiating_device_identifier_instance => undef,
        monitored_object_identifier_type      => undef,
        monitored_object_identifier_instance  => undef,
        time_remaining                        => undef,
        list_of_values                        => undef,
        @_,
    );

    my $sequence_elements = [
        [
            'subscriber_process_identifier',
            BACnet::DataTypes::UnsignedInt->construct(
                $args{subscriber_process_identifier}, 0x00
            )
        ],
        [
            'initiating_device_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct(
                $args{initiating_device_identifier_type},
                $args{initiating_device_identifier_instance},
                0x01
            )
        ],
        [
            'monitored_object_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct(
                $args{monitored_object_identifier_type},
                $args{monitored_object_identifier_instance},
                0x02
            )
        ],
        [
            'time_remaining',
            BACnet::DataTypes::UnsignedInt->construct(
                $args{time_remaining}, 0x03
            )
        ],
        [ 'list_of_values', $args{list_of_values} ]
    ];

    return BACnet::DataTypes::SequenceValue->construct($sequence_elements);
}

our $request_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'subscriber_process_identifier',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'initiating_device_identifier',
        dt   => 'BACnet::DataTypes::ObjectIdentifier'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'monitored_object_identifier',
        dt   => 'BACnet::DataTypes::ObjectIdentifier'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 3,
        name => 'time_remaining',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    ),
    BACnet::DataTypes::Bone->construct(
        tag      => 4,
        name     => 'list_of_values',
        dt       => 'BACnet::DataTypes::SequenceOfValues',
        skeleton =>
          $BACnet::DataTypes::Enums::PropertyIdentifier::list_of_property_value_skeleton,
    ),
];

1;
