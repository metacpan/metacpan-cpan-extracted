#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'false' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Bool',
        value        => 0,
        debug_prints => 0,

    );
};

subtest 'true 1' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Bool',
        value        => 1,
        debug_prints => 0,
    );
};

subtest 'true 11' => sub {
    Utils::construct_self_parse_test_dt(
        class          => 'BACnet::DataTypes::Bool',
        value          => 11,
        expected_value => 1,
        debug_prints   => 0,

    );
};

subtest 'false context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Bool',
        value        => 0,
        debug_prints => 0,
        modified_tag => 20,
        bit_cmp      => "\xF9\x14\x00",

    );
};

subtest 'true 1 context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Bool',
        value        => 1,
        debug_prints => 0,
        modified_tag => 2,
        bit_cmp      => "\x29\x01",

    );
};

subtest 'true 11 context' => sub {
    Utils::construct_self_parse_test_dt(
        class          => 'BACnet::DataTypes::Bool',
        value          => 11,
        expected_value => 1,
        debug_prints   => 0,
        modified_tag   => 20,
        bit_cmp        => "\xF9\x14\x01",

    );
};

done_testing;
