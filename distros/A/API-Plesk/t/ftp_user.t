#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib 't';
use TestData;

BEGIN { 
    plan tests => 2;
    use_ok('API::Plesk::FTPUser'); 
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok($api->ftp_user, 'API::Plesk::FTPUser');

