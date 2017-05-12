#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Authz' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn = new Apache::Sling::Authn(\$sling);
throws_ok { my $authz = new Apache::Sling::Authz() } qr/no authn provided!/, 'Check authz creation fails without authn provided';
my $authz = new Apache::Sling::Authz(\$authn,'1','log.txt');
isa_ok $authz, 'Apache::Sling::Authz', 'authz';
ok( $authz->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $authz->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $authz->{ 'Message' } eq '',                      'Check Message set' );
ok( $authz->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $authz->{ 'Response' },                   'Check response defined' );

$authz->set_results( 'Test Message', undef );
ok( $authz->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $authz->{ 'Response' },        'Check response no longer defined' );

ok( my $authz_config = Apache::Sling::Authz->config($sling), 'check config function' );
ok( Apache::Sling::Authz->run($sling, $authz_config), 'check run function' );
throws_ok { Apache::Sling::Authz->run() } qr/No authz config supplied!/, 'check run function croaks with no config supplied';

