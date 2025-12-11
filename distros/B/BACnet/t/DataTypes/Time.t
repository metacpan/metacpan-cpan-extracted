#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '00:00:00,00 - context' => sub {
    Utils::construct_self_parse_test_time(
        class        => 'BACnet::DataTypes::Time',
        hour         => 0,
        minute       => 0,
        second       => 0,
        centisecond  => 0,
        modified_tag => 20,
    );
};

subtest '00:00:00,00' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 0,
        minute      => 0,
        second      => 0,
        centisecond => 0,
    );
};

subtest '12:34:56,78' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 12,
        minute      => 34,
        second      => 56,
        centisecond => 78,
    );
};

subtest '23:59:59,99' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 23,
        minute      => 59,
        second      => 59,
        centisecond => 99,
    );
};

subtest 'undef hour' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => undef,
        minute      => 30,
        second      => 15,
        centisecond => 20,
    );
};

subtest 'undef minute' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 10,
        minute      => undef,
        second      => 15,
        centisecond => 20,
    );
};

subtest 'undef second' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 10,
        minute      => 30,
        second      => undef,
        centisecond => 20,
    );
};

subtest 'undef centisecond' => sub {
    Utils::construct_self_parse_test_time(
        class       => 'BACnet::DataTypes::Time',
        hour        => 10,
        minute      => 30,
        second      => 15,
        centisecond => undef,
    );
};
done_testing;
