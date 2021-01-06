#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'UpdateZone';
my %tests = (
    good => [
        {
            params   => {
                zone_id => 'zone1',
                name => 'zone1',
            },
            expected => {
                path => {
                    ZoneID => 'zone1',
                },
                body => {
                    name => 'zone1',
                },
            },
            name => 'param zone_id and name passed',
        },
        {
            params   => {
                zone_id => 'zone1',
                name => 'zone1',
                ttl  => 2,
            },
            expected => {
                path => {
                    ZoneID => 'zone1',
                },
                body => {
                    name => 'zone1',
                    ttl  => 2,
                },
            },
            name => 'param zone_id, name and ttl passed',
        },
    ],
    bad => [
        {
            params   => {
                test => 2,
            },
            expected => {},
            name     => 'passed neither name nor zone_id',
        },
        {
            params   => {
                name => 'zone1',
            },
            expected => {},
            name     => 'passed only name',
        },
        {
            params   => {zone_id => 1},
            expected => {},
            name     => 'passed zone_id',
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
            is $params, undef, "no params for '$test->{name}'"; 
        }
    }
}

done_testing();
