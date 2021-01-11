#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'CreatePrimaryServer';
my %tests = (
    good => [
        {
            params   => {
                id      => 1,
                port    => '80',
                address => '192.168.123.1',
                zone_id => 'zone1',
            },
            expected => {
                body => {
                    port    => '80',
                    address => '192.168.123.1',
                    zone_id => 'zone1',
                }
            },
            name => 'param "test" passed',
        },
    ],
    bad => [
        {
            params   => {
                test => 2,
            },
            expected => {},
            name     => 'no "name" passed',
        },
        {
            params   => {},
            expected => {},
            name     => 'empty params',
        },
        {
            params   => {primary_server_id => 1},
            expected => {},
            name     => 'passed primary_server_id',
        },
        {
            params   => {
                port    => '1000938193',
                address => '192.168.123.1',
                zone_id => 'zone1',
            },
            expected => {
            },
            name => 'param "test" passed',
        },
        {
            params   => {
                port    => 'abc',
                address => '192.168.123.1',
                zone_id => 'zone1',
            },
            expected => {
            },
            name => 'param "test" passed',
        },
    ]
);

for my $type ( sort keys %tests ) {
    for my $test ( @{ $tests{$type} } ) {
        my ($params, @errors) = DNS::Hetzner::Schema->validate(
            $operation_id,
            $test->{params} // {}
        );

        if ( $type eq 'good' ) {
            ok !@errors, "no errors for $test->{name}";
            is_deeply $params, $test->{expected} // {}, "params for '$test->{name}' correct"; 
        }
        else {
            ok @errors, "errors for $test->{name}";
            is_deeply $params, undef, "no params for '$test->{name}'"; 
        }
    }
}

done_testing();
