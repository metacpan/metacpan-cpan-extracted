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

subtest 'simple - context' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::SequenceValue',
        value => [
            [ 'one', BACnet::DataTypes::Int->construct( 1, 0 ) ],
            [ 'two', BACnet::DataTypes::Int->construct( 2, 1 ) ],
        ],
        modified_tag    => 5,
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag  => 0,
                name => 'one',
                dt   => 'BACnet::DataTypes::Int'
            ),
            BACnet::DataTypes::Bone->construct(
                tag  => 1,
                name => 'two',
                dt   => 'BACnet::DataTypes::Int'
            ),
        ],
        debug_prints => 0,
    );
};

subtest 'simple' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::SequenceValue',
        value => [
            [ 'one', BACnet::DataTypes::Int->construct( 1, 0 ) ],
            [ 'two', BACnet::DataTypes::Int->construct( 2, 1 ) ],
        ],
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag  => 0,
                name => 'one',
                dt   => 'BACnet::DataTypes::Int'
            ),
            BACnet::DataTypes::Bone->construct(
                tag  => 1,
                name => 'two',
                dt   => 'BACnet::DataTypes::Int'
            ),
        ],
        debug_prints => 0,
    );
};

subtest 'recursive' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::SequenceValue',
        value => [
            [ 'one', BACnet::DataTypes::Int->construct( 1, 0 ) ],
            [ 'two', BACnet::DataTypes::Int->construct( 2, 1 ) ],
            [
                'three',
                BACnet::DataTypes::SequenceValue->construct(
                    [
                        [ 'four', BACnet::DataTypes::Int->construct( 4, 0 ) ],
                        [ 'five', BACnet::DataTypes::Int->construct( 5, 1 ) ],
                    ],
                    2
                )
            ]
        ],
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag  => 0,
                name => 'one',
                dt   => 'BACnet::DataTypes::Int'
            ),
            BACnet::DataTypes::Bone->construct(
                tag  => 1,
                name => 'two',
                dt   => 'BACnet::DataTypes::Int'
            ),
            BACnet::DataTypes::Bone->construct(
                tag      => 2,
                name     => 'three',
                dt       => 'BACnet::DataTypes::SequenceValue',
                skeleton => [
                    BACnet::DataTypes::Bone->construct(
                        tag  => 0,
                        name => 'four',
                        dt   => 'BACnet::DataTypes::Int'
                    ),
                    BACnet::DataTypes::Bone->construct(
                        tag  => 1,
                        name => 'five',
                        dt   => 'BACnet::DataTypes::Int'
                    ),
                ]
            ),
        ],
        debug_prints => 0,
    );
};

done_testing;
