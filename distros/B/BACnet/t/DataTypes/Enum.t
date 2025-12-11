#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'Enum 5 - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Enum',
        value        => 0,
        modified_tag => 20,
        debug_prints => 0,
    );
};

subtest 'Enum 0' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 0,
    );
};

subtest 'Enum 1' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 1,
    );
};

subtest 'Enum 100000' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 100000,
    );
};

subtest 'Enum 255 (1 byte max)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 255,
    );
};

subtest 'Enum 256 (needs 2 bytes)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 256,
    );
};

subtest 'Enum 65535 (2 bytes max)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 65535,
    );
};

subtest 'Enum 65536 (needs 3 bytes)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 65536,
    );
};

subtest 'Enum large 32bit full' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 2**32 - 1,
    );
};

subtest 'Enum large (needs 5 bytes)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Enum',
        value => 2**32,
    );
};

subtest '2 ^ 56 - 1' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Enum',
        value        => 2**56 - 1,
        debug_prints => 0,
    );
};


done_testing;
