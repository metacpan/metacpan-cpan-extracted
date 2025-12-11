#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Int;

my $sequence = BACnet::DataTypes::SequenceValue->construct(
    [ [ 'one', BACnet::DataTypes::Int->construct(1), ] ] );

my $skeleton = [
    BACnet::DataTypes::Bone->construct(
        dt   => 'BACnet::DataTypes::Int',
        name => 'one',
    ),
];

my $empty_seq = BACnet::DataTypes::SequenceValue->construct( [] );

subtest 'basic' => sub {
    Utils::construct_self_parse_test_error(
        class            => 'BACnet::PDUTypes::Error',
        constructor_args => {
            invoke_id       => 10,
            service_choice  => 'GetAlarmSummary',
            service_request => $sequence,
        },
        debug_prints => 0,
        skeleton     => $skeleton,
    );
};

subtest 'invoke id 0' => sub {
    Utils::construct_self_parse_test_error(
        class            => 'BACnet::PDUTypes::Error',
        constructor_args => {
            invoke_id       => 0,
            service_choice  => 'GetAlarmSummary',
            service_request => $sequence,
        },
        debug_prints => 0,
        skeleton     => $skeleton,
    );
};

subtest 'empty service request' => sub {
    Utils::construct_self_parse_test_error(
        class            => 'BACnet::PDUTypes::Error',
        constructor_args => {
            invoke_id       => 0,
            service_choice  => 'GetAlarmSummary',
            service_request => $empty_seq,
        },
        debug_prints => 0,
        skeleton     => 1,
    );
};

done_testing;
