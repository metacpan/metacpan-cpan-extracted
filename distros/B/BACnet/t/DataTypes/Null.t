#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'null - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Null',
        value        => 0,
        debug_prints => 0,
        modified_tag => 20,
    );
};

subtest 'null' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::Null',
        value        => 0,
        debug_prints => 0,
    );
};

done_testing;
