#!/usr/bin/perl

use strict;
use warnings;



use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '42 - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::UnsignedInt',
        value        => 42,
        modified_tag => 20,
    );
};

subtest '0' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => 0,
    );
};

subtest '1' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => 1,
    );
};

subtest '12345' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => 12345,
    );
};

subtest '65535' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => 65535,
    );
};

subtest 'maximum 32-bit' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => ( 2**32 ) - 1,
    );
};

subtest 'maximum 56-bit' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::UnsignedInt',
        value => ( 2**56 ) - 1,
    );
};

subtest 'range 0..49' => sub {
    for my $i ( 0 .. 49 ) {
        Utils::construct_self_parse_test_dt(
            class => 'BACnet::DataTypes::UnsignedInt',
            value => $i,
        );
    }
};

done_testing;
