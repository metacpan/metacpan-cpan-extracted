#!perl

use strict;
use warnings;

use JSON;

package TestResource;

use Moo;
extends "Business::GoCardless::Resource";

has [ qw/
    name
    age
    alive
    time
/ ] => (
    is => 'rw',
);

1;

package main;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON;

use Business::GoCardless::Client;

isa_ok(
    my $TestResource = TestResource->new(
        name   => "Lee",
        age    => 30,
        alive  => JSON::true,
        time   => "2014-08-20T21:41:25Z",
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
    ),
    'Business::GoCardless::Resource'
);

isa_ok( $TestResource,'TestResource' );

can_ok(
    $TestResource,
    qw/
        endpoint
        client
        to_hash
        to_json
        name
        age
        alive
        time
    /,
);

is( $TestResource->endpoint,'/test_resources/%s','endpoint' );

cmp_deeply(
    { $TestResource->to_hash },
    {
        'age' => 30,
        'alive' => JSON::true,
        'endpoint' => '/test_resources/%s',
        'name' => 'Lee',
        'time' => '2014-08-20T21:41:25Z'
    },
    'to_hash'
);

is(
    $TestResource->to_json,
    JSON->new->canonical->encode( {
        'age' => 30,
        'alive' => JSON::true,
        'endpoint' => '/test_resources/%s',
        'name' => 'Lee',
        'time' => '2014-08-20T21:41:25Z'
    } ),
    'to_json'
);

done_testing();

# vim: ts=4:sw=4:et
