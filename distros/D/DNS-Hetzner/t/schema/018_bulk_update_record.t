#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'BulkUpdateRecords';
my %tests = (
    good => [
        {
            params   => {
                records => [
                    {
                        name    => 'record1',
                        type    => 'A',
                        value   => '192.168.123.1',
                        zone_id => 'zone1',
                    },
                ]
            },
            expected => {
                body => {
                    records => [
                        {
                            name    => 'record1',
                            type    => 'A',
                            value   => '192.168.123.1',
                            zone_id => 'zone1',
                        },
                    ]
                }
            },
            name => 'bulk record',
        },
        {
            params   => {
                records => [
                    {
                        name    => 'record1',
                        type    => 'A',
                        value   => '192.168.123.1',
                        zone_id => 'zone1',
                        ttl     => 2,
                    }
                ],
            },
            expected => {
                body => {
                    records => [
                        {
                            name    => 'record1',
                            type    => 'A',
                            value   => '192.168.123.1',
                            zone_id => 'zone1',
                            ttl     => 2,
                        },
                    ],
                }
            },
            name => 'bulk record with ttl',
        },
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
