#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Int;
use BACnet::ServiceRequestSequences::SubscribeCOV;

my $request = BACnet::ServiceRequestSequences::SubscribeCOV::request(
    subscriber_process_identifier        => 1,
    monitored_object_identifier_type     => 0,
    monitored_object_identifier_instance => 3,
    issue_confirmed_notifications        => 1,
    lifetime                             => 100,
);

my $request_unsubscribe = BACnet::ServiceRequestSequences::SubscribeCOV::request(
    subscriber_process_identifier        => 1,
    monitored_object_identifier_type     => 0,
    monitored_object_identifier_instance => 3,
);

subtest 'basic request' => sub {
    Utils::service_request_test(
        service_request => $request,
        skeleton        =>
          $BACnet::ServiceRequestSequences::SubscribeCOV::request_skeleton,
        debug_prints => 0,
    );
};

subtest 'unsubscribe' => sub {
    Utils::service_request_test(
        service_request => $request,
        skeleton        =>
          $BACnet::ServiceRequestSequences::SubscribeCOV::request_skeleton,
        debug_prints => 0,
    );
};

my $negative_response_request = BACnet::ServiceRequestSequences::SubscribeCOV::negative_response(
    error_class => 1,
    error_code  => 2,
);

subtest 'negative response' => sub {
    Utils::service_request_test(
        service_request => $negative_response_request,
        skeleton        =>
          $BACnet::ServiceRequestSequences::SubscribeCOV::negative_response_skeleton,
        debug_prints => 0,
    );
};

done_testing;
