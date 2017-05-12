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
    use_ok('API::Plesk::Customer'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

my $customers = API::Plesk::Customer->new( plesk => $api );

isa_ok($customers, 'API::Plesk::Customer');

is_deeply(
    $customers->get(id => 1, bulk_send => 1),
    { 
        filter => {id => 1},
        dataset => [ {gen_info => ''}, {stat => ''} ]
    },
    'get'
);
    
