#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;
use BACnet::DataTypes::Int;
use BACnet::DataTypes::SequenceValue;
use BACnet::DataTypes::UnsignedInt;
use BACnet::DataTypes::Bone;

my $sequence_value = [
    BACnet::DataTypes::Int->construct(0),
    BACnet::DataTypes::Int->construct(0),
    BACnet::DataTypes::Int->construct(0),
    BACnet::DataTypes::Int->construct(0),
    BACnet::DataTypes::Int->construct(0),
    BACnet::DataTypes::Int->construct(0)
];

subtest '[0,0,0,0,0,0] - context' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::SequenceOfValues',
        value           => $sequence_value,
        modified_tag    => 5,
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag      => undef,
                name     => undef,
                dt       => 'BACnet::DataTypes::Int',
                skeleton => undef,
            )
        ],
    );
};

subtest '[] - context' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::SequenceOfValues',
        value           => [],
        modified_tag    => 5,
        array_extractor => 0,
        head_check      => 0,
    );
};

subtest '[]' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::SequenceOfValues',
        value           => [],
        array_extractor => 0,
        head_check      => 0,
    );
};

subtest '[0,0,0,0,0,0]' => sub {
    Utils::construct_self_parse_test_dt(
        class           => 'BACnet::DataTypes::SequenceOfValues',
        value           => $sequence_value,
        array_extractor => 0,
        head_check      => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                tag      => undef,
                name     => undef,
                dt       => 'BACnet::DataTypes::Int',
                skeleton => undef,
            )
        ],
    );
};

subtest 'Sequence of SequenceValue -context' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::SequenceOfValues',
        value => [
            BACnet::DataTypes::SequenceValue->construct(
                [
                    [ 'int', BACnet::DataTypes::Int->construct( 0, 0 ) ],
                    [
                        'uint',
                        BACnet::DataTypes::UnsignedInt->construct( 0, 1 )
                    ]
                ],
                10
            ),
            BACnet::DataTypes::SequenceValue->construct(
                [
                    [ 'int', BACnet::DataTypes::Int->construct( 11, 0 ) ],
                    [
                        'uint',
                        BACnet::DataTypes::UnsignedInt->construct( 12, 1 )
                    ]
                ],
                10
            ),
        ],
        array_extractor => 0,
        head_check      => 0,
        modified_tag    => 1,
        debug_prints    => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                dt       => 'BACnet::DataTypes::SequenceValue',
                skeleton => [
                    BACnet::DataTypes::Bone->construct(
                        tag  => 0,
                        name => 'int',
                        dt   => 'BACnet::DataTypes::Int',
                    ),
                    BACnet::DataTypes::Bone->construct(
                        tag  => 1,
                        name => 'uint',
                        dt   => 'BACnet::DataTypes::UnsignedInt',
                    )
                ]
            )
        ],
    );
};

subtest 'Sequence of SequenceValue - without inner context' => sub {
    Utils::construct_self_parse_test_dt(
        class => 'BACnet::DataTypes::SequenceOfValues',
        value => [
            BACnet::DataTypes::SequenceValue->construct(
                [
                    [ 'int', BACnet::DataTypes::Int->construct( 0, 0 ) ],
                    [
                        'uint',
                        BACnet::DataTypes::UnsignedInt->construct( 0, 1 )
                    ]
                ],
                10
            ),
            BACnet::DataTypes::SequenceValue->construct(
                [
                    [ 'int', BACnet::DataTypes::Int->construct( 11, 0 ) ],
                    [
                        'uint',
                        BACnet::DataTypes::UnsignedInt->construct( 12, 1 )
                    ]
                ],
                10
            ),
        ],
        array_extractor => 0,
        head_check      => 0,
        modified_tag    => 1,
        debug_prints    => 0,
        skeleton        => [
            BACnet::DataTypes::Bone->construct(
                dt       => 'BACnet::DataTypes::SequenceValue',
                skeleton => [
                    BACnet::DataTypes::Bone->construct(
                        tag  => 0,
                        name => 'int',
                        dt   => 'BACnet::DataTypes::Int',
                    ),
                    BACnet::DataTypes::Bone->construct(
                        tag  => 1,
                        name => 'uint',
                        dt   => 'BACnet::DataTypes::UnsignedInt',
                    )
                ]
            )
        ],
    );
};

done_testing;
