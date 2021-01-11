#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'DeletePrimaryServer';
my %tests = (
    good => [
        {
            params   => {
                primary_server_id => 'test'
            },
            expected => {
                path => {
                    PrimaryServerID => 'test'
                },
            },
            name     => 'param "primary_server_id" passed',
        },
    ],
    bad => [
        {
            params   => {
                test => 2,
            },
            expected => {},
            name     => 'no "primary_server_id" passed',
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
