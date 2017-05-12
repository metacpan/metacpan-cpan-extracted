#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 7;
    use_ok('API::Plesk::Webspace'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->webspace, 'API::Plesk::Webspace');

is_deeply(
    $api->webspace->add(
        'plan-name' => '123',
        gen_setup   => {
            name          => '123',
            ip_address    => '123',
            'owner-login' => '123',
        },
        hosting     => {
            type       => 'vrt_hst',
            ftp_login  => '123',
            ftp_password => '123',
            ip_address => '123',
        },
        prefs => { www => 'true' },
        bulk_send   => 1,
    ),
    [
        {
            gen_setup   => [
                {name          => '123'},
                {'owner-login' => '123'},
                {ip_address    => '123'},
            ],
        },
        {
            hosting     => {
                vrt_hst => [
                    { property => [ {name => 'ftp_login'}, {value  => '123'} ] },
                    { property => [ {name => 'ftp_password'}, {value => '123'} ] },
                    { ip_address => '123' },
                ]
            },
        },
        {   prefs => { www => 'true' } },
        { 'plan-name' => '123' },
    ],
    'add'
);

is_deeply(
    $api->webspace->set(
        filter => { name => '123' },
        gen_setup   => {
            name          => '123',
            ip_address    => '123',
            'owner-login' => '123',
        },
        hosting     => {
            type       => 'vrt_hst',
            ftp_login  => '123',
            ftp_password => '123',
            ip_address => '123',
        },
        prefs => { www => 'true' },
        bulk_send   => 1,
    ),
    [
        { filter => { name => '123' } },
        { values => [
            {
                gen_setup   => [
                    {name          => '123'},
                    {'owner-login' => '123'},
                    {ip_address    => '123'},
                ],
            },
            {
                hosting     => {
                    vrt_hst => [
                        { property => [ {name => 'ftp_login'}, {value  => '123'} ] },
                        { property => [ {name => 'ftp_password'}, {value => '123'} ] },
                        { ip_address => '123' },
                    ]
                },
            },
            { prefs => { www => 'true' } },
       ]},
    ],
    'set'
);


is_deeply(
    $api->webspace->add_subscription(
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {'plan-guid' => 'wervqwef'},
    ]
);

is_deeply(
    $api->webspace->remove_subscription(
        filter      => {'owner-name' => 'qwerty'},
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {filter      => {'owner-name' => 'qwerty'}},
        {'plan-guid' => 'wervqwef'},
    ]
);


is_deeply(
    $api->webspace->switch_subscription(
        filter      => {'owner-name' => 'qwerty'},
        'plan-guid' => 'wervqwef',
        bulk_send   => 1
    ),
    [
        {filter      => {'owner-name' => 'qwerty'}},
        {'plan-guid' => 'wervqwef'},
    ]
);
        
