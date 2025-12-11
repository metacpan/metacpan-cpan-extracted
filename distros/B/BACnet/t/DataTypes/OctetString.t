#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest '4B - context' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::OctetString',
        value        => "abcd",
        modified_tag => 20,
    );
};

subtest '4B' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "abcd",
    );
};

subtest 'empty' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "",
    );
};

subtest '8B' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "1234567",
    );
};

subtest 'OctetString long' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    );
};

subtest 'OctetString special chars' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "\x00\x01\x02\xFF",
    );
};

subtest 'OctetString very long' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::OctetString',
        value => "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    );
};

done_testing;
