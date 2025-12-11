#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '127 - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Int',
        value        => 127,
        modified_tag => 20,
    );
};

subtest '0' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 0,
    );
};

subtest '1' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 1,
    );
};

subtest '2' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 2,
    );
};

subtest '127' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 127,
    );
};

subtest '128' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 128,
    );
};

subtest '255' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 255,
    );
};

subtest '256' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 256,
    );
};

subtest '257' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 257,
    );
};

subtest '65535' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 65535,
    );
};

subtest '65536' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 65536,
    );
};

subtest '2^28 - 1 (Max)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => 2**28 - 1,
    );
};

# negative

subtest '-1' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -1,
    );
};

subtest '-2' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -2,
    );
};

subtest '-127' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -127,
    );
};

subtest '-128' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -128,
    );
};

subtest '-255' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -255,
    );
};

subtest '-256' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -256,
    );
};

subtest '-257' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -257,
    );
};

subtest '-65535' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -65535,
    );
};

subtest '-65536' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -65536,
    );
};

subtest '- (2^28)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Int',
        value => -( 2**28 ),
    );
};

done_testing;
