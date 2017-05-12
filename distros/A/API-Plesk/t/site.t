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
    use_ok('API::Plesk::Site'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->site, 'API::Plesk::Site');

is_deeply(
    $api->site->add(
        gen_setup => {
            name => 'test.ru',
            'webspace-name' => 'main.ru',
        },
        hosting => {
            type => 'std_fwd',
            ip_address => '12.34.56.78',
            dest_url => 'fwd.ru',
        },
        bulk_send => 1
    ),
    [ 
        {gen_setup => [
            {name => 'test.ru'},
            {'webspace-name' => 'main.ru'},
        ]},
        {hosting => {
            std_fwd => {
                dest_url => 'fwd.ru',
                ip_address => '12.34.56.78',
            }
        }}

    ],
    'add'
);

is_deeply(
    $api->site->set(
        filter => {name => 'test.ru'},
        gen_setup => {
            name => 'test.ru',
        },
        hosting => {
            type => 'vrt_hst',
            ip_address => '12.34.56.78',
            ftp_login => 'qwerty',
            ftp_password => '12345',
            ip_address => '12.34.56.78',
        },
        bulk_send => 1
    ),
    {
        filter => {name => 'test.ru'},
        values => [
            {gen_setup => {
                name => 'test.ru',
            }},
            {hosting => {
                vrt_hst => [
                    { property => [
                        {name => 'ftp_login'},
                        {value => 'qwerty'}
                    ]},
                    { property => [
                        {name => 'ftp_password'},
                        {value => '12345'}
                    ]},
                    {ip_address => '12.34.56.78'},
                ]
            }}
        ]

    },
    'set'
);

is_deeply(
    $api->site->del(
        name      => 'test.ru',
        bulk_send => 1
    ),
    { 
        filter => {name => 'test.ru'},
    },
    'del'
);
