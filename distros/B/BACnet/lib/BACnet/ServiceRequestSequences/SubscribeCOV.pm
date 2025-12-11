#!/usr/bin/perl

package BACnet::ServiceRequestSequences::SubscribeCOV;

use warnings;
use strict;

require BACnet::ServiceRequestSequences::Utils;

require BACnet::DataTypes::Bool;
require BACnet::DataTypes::Enum;
require BACnet::DataTypes::Int;
require BACnet::DataTypes::ObjectIdentifier;
require BACnet::DataTypes::SequenceValue;
require BACnet::DataTypes::SequenceOfValues;
require BACnet::DataTypes::UnsignedInt;
require BACnet::DataTypes::DataType;

require BACnet::DataTypes::Bone;

our $request_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag  => 0,
        name => 'subscriber_process_identifier',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 1,
        name => 'monitored_object_identifier',
        dt   => 'BACnet::DataTypes::ObjectIdentifier'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 2,
        name => 'issue_confirmed_notifications',
        dt   => 'BACnet::DataTypes::Bool'
    ),
    BACnet::DataTypes::Bone->construct(
        tag  => 3,
        name => 'lifetime',
        dt   => 'BACnet::DataTypes::UnsignedInt'
    ),
];

sub request {
    my %args = (
        subscriber_process_identifier        => undef,
        monitored_object_identifier_type     => undef,
        monitored_object_identifier_instance => undef,
        issue_confirmed_notifications        => undef,
        lifetime                             => undef,
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
            'monitored_object_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct(
                $args{monitored_object_identifier_type},
                $args{monitored_object_identifier_instance},
                0x01
            )
        ],
    ];

    if ( defined $args{issue_confirmed_notifications} ) {
        push @$sequence_elements,
          [
            'issue_confirmed_notifications',
            BACnet::DataTypes::Bool->construct(
                $args{issue_confirmed_notifications}, 0x02
            )
          ],
          [
            'lifetime',
            BACnet::DataTypes::UnsignedInt->construct( $args{lifetime}, 0x03 ),
          ];
    }

    return BACnet::DataTypes::SequenceValue->construct($sequence_elements);
}

our $negative_response_skeleton =
  $BACnet::ServiceRequestSequences::Utils::error_type_skeleton;

sub negative_response {
    return BACnet::ServiceRequestSequences::Utils::_error_type(@_);
}
1;
