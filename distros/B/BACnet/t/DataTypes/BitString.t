#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

subtest 'simple 8 bits' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::BitString',
        value        => '10101010',
        debug_prints => 0,
        bit_cmp      => "\x82\x00\xAA",
    );
};

subtest 'less than 8 bits' => sub {
    Utils::construct_self_parse_test_dt(
        class   => 'BACnet::DataTypes::BitString',
        value   => '101',
        bit_cmp => "\x82\x05\xA0",
    );
};

subtest 'more than 8 bits' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::BitString',
        value        => '101010101010',
        debug_prints => 0,
        bit_cmp      => "\x83\x04\xAA\xA0",
    );
};

subtest 'all zeros' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '00000000',
    );
};

subtest 'all ones' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '11111111',
    );
};

subtest 'edge case: 1 bit' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1',
    );
};

subtest 'edge case: 0 bits (empty)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '',
    );
};

subtest 'long bit string' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value =>
'1111111111111111111111111111111111111111111111100000000000000000000000000000000001111111111111111111111111111111111100000000000001111111111111111111',
        bit_cmp =>
"\x85\x14\x04\xFF\xFF\xFF\xFF\xFF\xFE\x00\x00\x00\x00\x7F\xFF\xFF\xFF\xF0\x00\x7F\xFF\xF0",
    );
};

subtest 'single bit: 1' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1',
    );
};

subtest 'single bit: 0' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '0',
    );
};

subtest 'full byte: all ones' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '11111111',
    );
};

subtest 'full byte: alternating pattern' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '10101010',
    );
};

subtest 'full byte: all zeros' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '00000000',
    );
};

subtest 'multi-byte: 16 bits' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1111000011110000',
    );
};

subtest 'multi-byte: odd length (7 bits)' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1010101',
    );
};

subtest 'multi-byte: long 64 bits' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1' x 64,
    );
};

subtest 'mixed bits: long irregular pattern' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => '1100110010101010111110000001111',
    );
};

subtest 'long 128 bits alternating pattern' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::BitString',
        value => ( '1100' x 32 ),
    );
};

subtest 'long 2^15 bits alternating pattern' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::BitString',
        value        => ( '1010' x ( 2**16 ) ),
        debug_prints => 0,
    );
};

subtest 'long 2^18 bits alternating pattern' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::BitString',
        value        => ( '1010' x ( 2**19 ) ),
        debug_prints => 0,
    );
};

subtest 'context tagged' => sub {
    Utils::construct_self_parse_test_dt(
        class        => 'BACnet::DataTypes::BitString',
        value        => '10101010',
        debug_prints => 0,
        bit_cmp      => "\xFA\x14\x00\xAA",
        modified_tag => 20,
    );
};

subtest 'Brut force' => sub {
    for my $length ( 900 .. 1000 ) {
        subtest 'pseudo random string' => sub {
            Utils::construct_self_parse_test_dt(
                class => 'BACnet::DataTypes::BitString',
                value => Utils::rng_bit_string( Utils::TEST_SEED, $length ),
                debug_prints => 0,
            );
        };
    }
};

done_testing;
