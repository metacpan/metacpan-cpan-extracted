#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'CreateZone';
my %tests = (
    good => [
        {
            params   => {
                name => 'zone1',
            },
            expected => {
                body => {
                    name => 'zone1',
                },
            },
            name => 'param "test" passed',
        },
        {
            params   => {
                name => 'zone1',
                ttl  => 2,
            },
            expected => {
                body => {
                    name => 'zone1',
                    ttl  => 2,
                },
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
