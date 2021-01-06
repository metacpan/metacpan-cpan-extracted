#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner::Schema;

my $operation_id = 'GetZones';
my %tests = (
    good => [
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
        {
            params   => {page => 1},
            expected => {
                query => {
                    page => 1,
                },
            },
            name     => 'passed page',
        },
        {
            params   => {name => 'test', page => 1},
            expected => {
                query => {
                    page => 1,
                    name => 'test',
                },
            },
            name     => 'passed name and page',
        },
        {
            params   => {name => 'test', page => 1, per_page => 100},
            expected => {
                query => {
                    page => 1,
                    name => 'test',
                    per_page => 100,
                },
            },
            name     => 'passed name, page and per_page',
        },
        {
            params   => {name => 'test', page => 1, per_page => 100, search_name => 'te'},
            expected => {
                query => {
                    page => 1,
                    name => 'test',
                    per_page => 100,
                    search_name => 'te',
                },
            },
            name     => 'passed name, page, per_page and search_name',
        },
    ],
    bad => [
        {
            params   => {page => 'abc'},
            expected => {},
            name     => 'passed page "abc"',
        },
        {
            params   => {page => 0 },
            expected => {},
            name     => 'passed page "0"',
        },
        {
            params   => {page => -1 },
            expected => {},
            name     => 'passed page "-1"',
        },
        {
            params   => {page => { test => 1 } },
            expected => {},
            name     => 'passed page (object)',
        },
        {
            params   => {name => { test => 1 } },
            expected => {},
            name     => 'passed name (object)',
        },
        {
            params   => {per_page => 101},
            expected => {},
            name     => 'passed per_page "101"',
        },
        {
            params   => {per_page => -101},
            expected => {},
            name     => 'passed per_page "-101"',
        },
        {
            params   => {per_page => "abc"},
            expected => {},
            name     => 'passed per_page "abc"',
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
            TODO : {
                local $TODO = 'Still working on validation';
                ok @errors, "errors for $test->{name}";
                is $params, undef, "no params for '$test->{name}'"; 
            };
        }
    }
}

done_testing();
