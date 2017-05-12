#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib qw(lib t);
use TestData;

BEGIN { 
    plan tests => 6;
    use_ok('API::Plesk::Database'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->database, 'API::Plesk::Database');

is_deeply(
    $api->database->add_db(
        'webspace-id' => 1,
        name => 'test_db',
        type => 'MySQL',
        bulk_send => 1
    ),
    { 
        'webspace-id' => 1,
        name => 'test_db',
        type => 'MySQL',
    },
    'add_db'
);

is_deeply(
    $api->database->del_db(
        name => 'test_db',
        bulk_send => 1
    ),
    { 
        filter => {name => 'test_db'},
    },
    'del_db'
);
is_deeply(
    $api->database->add_db_user(
        'db-id'   => 1,
        login     => 'test_db_user',
        password  => '12345',
        bulk_send => 1
    ),
    [ 
        {'db-id'   => 1},
        {login     => 'test_db_user'},
        {password  => '12345'},
    ],
    'add_db_user'
);
 is_deeply(
    $api->database->del_db_user(
        'db-id' => 1,
        bulk_send => 1
    ),
    {
        filter => {'db-id' => 1} 
    },
    'del_db_user'
);
 
