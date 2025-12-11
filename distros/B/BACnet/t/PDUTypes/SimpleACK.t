#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'basic' => sub {
    Utils::construct_self_parse_test_simple_ack(
        class            => 'BACnet::PDUTypes::SimpleACK',
        constructor_args => {
            invoke_id      => 10,
            service_choice => 'ConfirmedCOVNotification',
        },
        debug_prints => 0,
    );
};

subtest 'invoke id 0' => sub {
    Utils::construct_self_parse_test_simple_ack(
        class            => 'BACnet::PDUTypes::SimpleACK',
        constructor_args => {
            invoke_id      => 0,
            service_choice => 'ConfirmedCOVNotification',
        },
        debug_prints => 0,
    );
};

done_testing;
