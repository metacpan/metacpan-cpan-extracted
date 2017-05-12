#!perl -T
use 5.16.0;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use App::Docker::Client;

plan tests => 7;

my $client = new_ok( 'App::Docker::Client' => [] );

is $client->scheme,    'http';
is $client->authority, '/var/run/docker.sock';
is $client->json->isa('JSON'), 1;

my $test_container = File::Spec->catfile( $Bin, 'data' );
is $client->authority($test_container), $test_container;
is $client->scheme('file'), 'file';
is $client->json->isa('JSON'), 1;

