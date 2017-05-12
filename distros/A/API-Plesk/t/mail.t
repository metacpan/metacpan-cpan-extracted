#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 4;
    use_ok('API::Plesk::Mail'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->mail, 'API::Plesk::Mail');

is_deeply(
    $api->mail->enable(
        site_id => 123,
        bulk_send => 1,
    ),
    { 
        site_id => 123,
    },
    'enable'
);

is_deeply(
    $api->mail->disable(
        site_id => 123,
        bulk_send => 1,
    ),
    { 
        site_id => 123,
    },
    'disable'
);
