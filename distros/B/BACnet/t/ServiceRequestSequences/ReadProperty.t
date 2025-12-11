#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Int;
use BACnet::DataTypes::CharString;
use BACnet::DataTypes::SequenceValue;
use BACnet::ServiceRequestSequences::ReadProperty;

my $request = BACnet::ServiceRequestSequences::ReadProperty::request(
    object_identifier_type     => 1,
    object_identifier_instance => 2,
    property_identifier        => 3,
    property_array_index       => 4,
);

my $request_short = BACnet::ServiceRequestSequences::ReadProperty::request(
    object_identifier_type     => 1,
    object_identifier_instance => 2,
    property_identifier        => 3,
);

subtest 'basic request' => sub {
    Utils::service_request_test(
        service_request => $request,
        skeleton        =>
          $BACnet::ServiceRequestSequences::ReadProperty::request_skeleton,
        debug_prints => 0,
    );
};

subtest 'without property array index' => sub {
    Utils::service_request_test(
        service_request => $request_short,
        skeleton        =>
          $BACnet::ServiceRequestSequences::ReadProperty::request_skeleton,
        debug_prints => 0,
    );
};

my $negative_response =
  BACnet::ServiceRequestSequences::ReadProperty::negative_response(
    error_class => 1,
    error_code  => 2,
  );

subtest 'negative response' => sub {
    Utils::service_request_test(
        service_request => $negative_response,
        skeleton        =>
          $BACnet::ServiceRequestSequences::ReadProperty::negative_response_skeleton,
        debug_prints => 0,
    );
};

my $char_string_in_wrapper = BACnet::DataTypes::SequenceValue->construct(
    [
        [
            'value',
            BACnet::DataTypes::CharString->construct( "strom", "ascii" )
        ]
    ],
    0x03
);

my $positive_response =
  BACnet::ServiceRequestSequences::ReadProperty::positive_response(
    object_identifier_type     => 1,
    object_identifier_instance => 2,
    property_identifier        => 44,
    property_array_index       => 0,
    property_value             => $char_string_in_wrapper,
  );


my $positive_response_short =
  BACnet::ServiceRequestSequences::ReadProperty::positive_response(
    object_identifier_type     => 1,
    object_identifier_instance => 2,
    property_identifier        => 44,
    property_value             => $char_string_in_wrapper,
  );

subtest 'positive response without property array index' => sub {
    Utils::service_request_test(
        service_request => $positive_response_short,
        skeleton        =>
          $BACnet::ServiceRequestSequences::ReadProperty::positive_response_skeleton,
        debug_prints => 0,
    );
};
done_testing;
