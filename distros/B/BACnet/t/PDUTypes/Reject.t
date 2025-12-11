#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'basic' => sub {
    Utils::construct_self_parse_test_reject(
        class            => 'BACnet::PDUTypes::Reject',
        constructor_args => {
            invoke_id      => 10,
            service_choice => 'InvalidTag',
        },
        debug_prints => 0,
    );
};

subtest 'invoke id 0' => sub {
    Utils::construct_self_parse_test_reject(
        class            => 'BACnet::PDUTypes::Reject',
        constructor_args => {
            invoke_id      => 0,
            service_choice => 'InvalidTag',
        },
        debug_prints => 0,
    );
};

done_testing;
