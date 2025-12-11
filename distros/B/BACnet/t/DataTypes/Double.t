#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '15 - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Double',
        value        => 0,
        debug_prints => 0,
        modified_tag => 20,
    );
};

subtest '0' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Double',
        value        => 0,
        debug_prints => 0,
    );
};

subtest '10' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Double',
        value => 10,
    );
};

subtest '-10' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Double',
        value => -10,
    );
};

subtest '10^10' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Double',
        value => 10000000000,
    );
};

subtest '-(10^10)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Double',
        value => -10000000000,
    );
};

done_testing;
