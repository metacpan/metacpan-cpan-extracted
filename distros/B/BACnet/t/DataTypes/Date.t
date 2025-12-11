#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '2025-05-06, day 4 (Wednesday) - modified tag' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2025,
        month           => 5,
        day             => 6,
        day_of_the_week => 4,
        modified_tag    => 20,
    );
};

subtest '2025-05-06, day 4 (Wednesday)' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2025,
        month           => 5,
        day             => 6,
        day_of_the_week => 4,
    );
};

subtest '2023-12-25, day 1 (Monday)' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2023,
        month           => 12,
        day             => 25,
        day_of_the_week => 1,
    );
};

subtest '2000-01-01, day 6 (Saturday)' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2000,
        month           => 1,
        day             => 1,
        day_of_the_week => 6,
    );
};

subtest '1999-07-04, day 7 (Sunday)' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 1999,
        month           => 7,
        day             => 4,
        day_of_the_week => 7,
    );
};

subtest '2024-02-29, day 5 (Thursday) - leap year' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2024,
        month           => 2,
        day             => 29,
        day_of_the_week => 5,
    );
};

subtest '2024-02-29, day 5 (undef) - leap year' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2024,
        month           => 2,
        day             => 29,
        day_of_the_week => undef,
    );
};

subtest '2024-02-undef, day 5 (Thursday) - leap year' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2024,
        month           => 2,
        day             => undef,
        day_of_the_week => 5,
    );
};

subtest '2024-undef-29, day 5 (Thursday) - leap year' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => 2024,
        month           => undef,
        day             => 29,
        day_of_the_week => 5,
    );
};

subtest 'undef-02-29, day 5 (Thursday) - leap year' => sub {
    Utils::construct_self_parse_test_date(
        class           => 'BACnet::DataTypes::Date',
        year            => undef,
        month           => 2,
        day             => 29,
        day_of_the_week => 5,
    );
};

done_testing;
