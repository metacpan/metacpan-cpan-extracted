#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'DeleteRecord';
my %tests = (
    good => [
        {
            params   => {
                record_id => 'record2',
            },
            expected => {
                path => {
                    RecordID => 'record2',
                }
            },
            name => 'param "test" passed',
        },
        {
            params   => {
                record_id => 'record2',
            },
            expected => {
                path => {
                    RecordID => 'record2',
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
