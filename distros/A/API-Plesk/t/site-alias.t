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
    use_ok('API::Plesk::SiteAlias'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->site_alias, 'API::Plesk::SiteAlias');

is_deeply(
    $api->site_alias->create(
        'site-id' => 12345,
        name => 'www.ru',
        bulk_send => 1
    ),
    { 
        'site-id' => 12345,
         name     => 'www.ru',
    },
    'create'
);

is_deeply(
    $api->site_alias->set(
        filter    => {'site-id' => 'test.ru'},
        settings  => { status => 1 },
        bulk_send => 1
    ),
    {
        filter   => {'site-id' => 'test.ru'},
        settings => { status => 1 },
    },
    'set'
);

is_deeply(
    $api->site_alias->del(
        'site-id' => 123,
        bulk_send => 1
    ),
    { 
        filter => {'site-id' => 123},
    },
    'del'
);
