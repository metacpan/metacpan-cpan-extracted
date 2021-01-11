#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'GetPrimaryServers';
my %tests = (
    good => [
        {
            params   => {
                zone_id => 'test'
            },
            expected => {
                query => {
                    zone_id => 'test',
                }
            },
            name     => 'param "zone_id" passed',
        },
        {
            params   => {
                record_id => 'test'
            },
            expected => {
            },
            name     => 'param "record_id" passed',
        },
        {
            params   => {
                test => 'test'
            },
            expected => {
            },
            name     => 'non-existant param "test" passed',
        },
        {
            params   => {},
            expected => {},
            name     => 'empty params',
        },
    ],
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
