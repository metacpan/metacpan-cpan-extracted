#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 5;
    use_ok('API::Plesk::ServicePlan'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->service_plan, 'API::Plesk::ServicePlan');

is_deeply(
    $api->service_plan->set(
        filter => { name => '123' },
        hosting     => {
            type       => 'vrt_hst',
            ftp_login  => '123',
            ftp_password => '123',
            ip_address => '123',
        },
        limits => '',
        bulk_send   => 1,
    ),
    [
        { filter => { name => '123' } },
        { limits => '' },
        {
            hosting     => {
                vrt_hst => [
                    { property => [ {name => 'ftp_login'}, {value  => '123'} ] },
                    { property => [ {name => 'ftp_password'}, {value => '123'} ] },
                    { ip_address => '123' },
                ]
            },
        },
    ],
    'set'
);

is_deeply(
    $api->service_plan->del(
        name      => 'test.ru',
        bulk_send => 1
    ),
    { 
        filter => {name => 'test.ru'},
    },
    'del'
);

is_deeply(
    $api->service_plan->get(
        filter => {
            name => 'Host-Lite',
        },
        'owner-id' => 123,
        bulk_send => 1,
    ),
    [
        { filter => { name => 'Host-Lite' } },
        { 'owner-id' => 123 },
    ],
    'get'
);

