#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '42 - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Real',
        value        => 42,
        modified_tag => 20,
    );
};

subtest '0' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Real',
        value => 0,
    );
};

subtest 'deterministic random' => sub {
    for my $i ( 1 .. 50 ) {
        my $val = $i * 0.5 - 12.5;
        subtest "$val" => sub {
            Utils::construct_self_parse_test_dt(
                class => 'BACnet::DataTypes::Real',
                value => $val,
            );
        };
    }
};


done_testing;
