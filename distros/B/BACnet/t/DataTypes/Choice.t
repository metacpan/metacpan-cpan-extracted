#!/usr/bin/perl


use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Int;
use BACnet::DataTypes::SequenceValue;
use BACnet::DataTypes::Bone;
use BACnet::DataTypes::Choice;

my $example_skeleton = [
    BACnet::DataTypes::Bone->construct(
        tag => 0,
        dt  => 'BACnet::DataTypes::CharString'
    ),
    BACnet::DataTypes::Bone->construct(
        tag => 1,
        dt  => 'BACnet::DataTypes::Int'
    ),
];

subtest 'simple - context' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::Choice',
        value           => BACnet::DataTypes::Int->construct( 2, 1 ),
        modified_tag    => 5,
        array_extractor => 0,
        head_check      => 0,
        skeleton        => $example_skeleton,
        debug_prints    => 0,
        wrapped         => 1,
    );
};

subtest 'simple' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::Choice',
        value           => BACnet::DataTypes::Int->construct( 2, 1 ),
        array_extractor => 0,
        head_check      => 0,
        skeleton        => $example_skeleton,
        debug_prints    => 0,
    );
};

subtest 'choice inside choice' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::Choice',
        value => BACnet::DataTypes::Choice->construct(
            BACnet::DataTypes::Int->construct( 2, 1 ), 5
        ),
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag => 4,
                dt  => 'BACnet::DataTypes::CharString'
            ),
            BACnet::DataTypes::Bone->construct(
                tag      => 5,
                dt       => 'BACnet::DataTypes::Choice',
                skeleton => $example_skeleton,
                wrapped  => 1,
            ),
            BACnet::DataTypes::Bone->construct(
                tag => 7,
                dt  => 'BACnet::DataTypes::Int'
            ),
        ],
        debug_prints => 0,
    );
};

done_testing;
