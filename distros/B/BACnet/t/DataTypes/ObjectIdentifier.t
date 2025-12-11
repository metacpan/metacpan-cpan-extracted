#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use lib './t';

use Utils;

use BACnet::DataTypes::ObjectIdentifier;

subtest "context" => sub {
    Utils::construct_self_parse_test_object_identifier(
        class        => 'BACnet::DataTypes::ObjectIdentifier',
        type         => 0,
        instance     => 42,
        modified_tag => 20,
    );
};

subtest 'All object types' => sub {
    for my $name (
        sort keys %{$BACnet::DataTypes::ObjectIdentifier::obj_types_rev} )
    {

        subtest $name => sub {
            Utils::construct_self_parse_test_object_identifier(
                class    => 'BACnet::DataTypes::ObjectIdentifier',
                type     => $name,
                instance => 42,
            );
        };
    }
};

subtest 'Analog-Input, obj instances' => sub {
    my $obj_ins = 0;
    for ( my $i = 0 ; $i < 10 ; $i++ ) {
        subtest $obj_ins => sub {
            Utils::construct_self_parse_test_object_identifier(
                class    => 'BACnet::DataTypes::ObjectIdentifier',
                type     => 0,
                instance => $obj_ins,
            );
        };

        $obj_ins = $obj_ins + $i * $obj_ins;
    }
};

subtest 'max obj instances' => sub {
    Utils::construct_self_parse_test_object_identifier(
        class    => 'BACnet::DataTypes::ObjectIdentifier',
        type     => 0,
        instance => ( 2**22 ) - 1,
    );
};

done_testing;
