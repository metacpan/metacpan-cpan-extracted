#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Enum;
use BACnet::DataTypes::Int;
use BACnet::DataTypes::UnsignedInt;
use BACnet::DataTypes::CharString;
use BACnet::DataTypes::SequenceValue;
use BACnet::DataTypes::SequenceOfValues;
use BACnet::ServiceRequestSequences::COVUnconfirmedNotification;
use BACnet::DataTypes::ObjectIdentifier;

my $elem1 = BACnet::DataTypes::SequenceValue->construct(
    [
        [
            'property_identifier',
            BACnet::DataTypes::Enum->construct( 44, 0x00 )
        ],
        [
            'value',
            BACnet::DataTypes::SequenceValue->construct(
                [
                    [
                        'value',
                        BACnet::DataTypes::CharString->construct(
                            "strom", "ascii"
                        )
                    ]
                ],
                0x02
            )
        ]
    ]
);

my $example_object_property_reference =
  BACnet::DataTypes::SequenceValue->construct(
    [
        [
            'object_identifier',
            BACnet::DataTypes::ObjectIdentifier->construct( 0, 1, 0x00 )
        ],
        [
            'property_identifier',
            BACnet::DataTypes::Enum->construct( 12, 0x01 )
        ],
        [
            'property_array_index',
            BACnet::DataTypes::UnsignedInt->construct( 17, 0x02 )
        ],
    ],
    0x02
  );

my $elem2 = BACnet::DataTypes::SequenceValue->construct(
    [
        [
            'property_identifier',
            BACnet::DataTypes::Enum->construct( 19, 0x00 )
        ],
        [ 'value', $example_object_property_reference, ]
    ]
);

my $list_of_values =
  BACnet::DataTypes::SequenceOfValues->construct( [ $elem1, $elem1, $elem1 ],
    4 );

my $list_of_values_complicated =
  BACnet::DataTypes::SequenceOfValues->construct( [$elem2], 4 );

our $request =
  BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request(
    subscriber_process_identifier         => 0,
    initiating_device_identifier_type     => 1,
    initiating_device_identifier_instance => 2,
    monitored_object_identifier_type      => 3,
    monitored_object_identifier_instance  => 4,
    time_remaining                        => 5,
    list_of_values                        => $list_of_values,
  );

our $request_complicated =
  BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request(
    subscriber_process_identifier         => 0,
    initiating_device_identifier_type     => 1,
    initiating_device_identifier_instance => 2,
    monitored_object_identifier_type      => 3,
    monitored_object_identifier_instance  => 4,
    time_remaining                        => 5,
    list_of_values                        => $list_of_values_complicated,
  );

subtest 'basic request' => sub {
    Utils::service_request_test(
        service_request => $request,
        skeleton        =>
          $BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request_skeleton,
        debug_prints => 0,
    );
};

subtest 'complicated request' => sub {
    Utils::service_request_test(
        service_request => $request_complicated,
        skeleton        =>
          $BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request_skeleton,
        debug_prints => 0,
    );
};

done_testing;
