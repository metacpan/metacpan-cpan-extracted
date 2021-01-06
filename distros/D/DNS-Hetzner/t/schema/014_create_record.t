#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'CreateRecord';
my %tests = (
    good => [
        {
            params   => {
                name    => 'record1',
                type    => 'A',
                value   => '192.168.123.1',
                zone_id => 'zone1',
            },
            expected => {
                body => {
                    name    => 'record1',
                    type    => 'A',
                    value   => '192.168.123.1',
                    zone_id => 'zone1',
                }
            },
            name => 'param "test" passed',
        },
        {
            params   => {
                name    => 'record1',
                type    => 'A',
                value   => '192.168.123.1',
                zone_id => 'zone1',
                ttl     => 2,
            },
            expected => {
                body => {
                    name    => 'record1',
                    ttl     => 2,
                    type    => 'A',
                    value   => '192.168.123.1',
                    zone_id => 'zone1',
                }
            },
            name => 'good - 2',
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
            params   => {record_id => 1},
            expected => {},
            name     => 'passed record_id',
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
