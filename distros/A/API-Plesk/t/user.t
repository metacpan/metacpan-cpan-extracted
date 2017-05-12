#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 3;
    use_ok('API::Plesk::User'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $users = $api->user;

isa_ok($users, 'API::Plesk::User');

is_deeply(
    $users->get(guid => 1, bulk_send => 1),
    { 
        filter => {guid => 1},
        dataset => [ {'gen-info' => ''}, {roles => ''} ]
    },
    'get'
);
    
