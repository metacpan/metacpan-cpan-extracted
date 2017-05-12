#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::JsonQueryServlet' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn = new Apache::Sling::Authn(\$sling);
throws_ok { my $json_query_servlet = new Apache::Sling::JsonQueryServlet() } qr/no authn provided!/, 'Check creating JsonQueryServlet croaks without authn provided';
my $json_query_servlet = new Apache::Sling::JsonQueryServlet(\$authn,'1','log.txt');

ok( $json_query_servlet->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $json_query_servlet->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $json_query_servlet->{ 'Message' } eq '',                      'Check Message set' );
ok( $json_query_servlet->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $json_query_servlet->{ 'Authn' },                      'Check authn defined' );
ok( defined $json_query_servlet->{ 'Response' },                   'Check response defined' );

$json_query_servlet->set_results( 'Test Message', undef );
ok( $json_query_servlet->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $json_query_servlet->{ 'Response' },        'Check response no longer defined' );

ok( my $json_query_servlet_config = Apache::Sling::JsonQueryServlet->config($sling), 'check config function' );
ok( Apache::Sling::JsonQueryServlet->run($sling,$json_query_servlet_config), 'check run function' );
throws_ok { Apache::Sling::JsonQueryServlet->run() } qr/No json query servlet config supplied!/, 'check run function croaks with no config supplied';
