#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'Verbose'} = 1;
$sling->{'Log'} = 'log.txt';

my $authn = new Apache::Sling::Authn(\$sling);
isa_ok $authn, 'Apache::Sling::Authn', 'authn';
ok( $authn->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( ! defined $authn->{ 'Type' },                     'Check Auth type not defined' );
ok( $authn->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $authn->{ 'Message' } eq '',                      'Check Message set' );
ok( $authn->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( ! defined $authn->{ 'Username' },                 'Check user name not defined' );
ok( ! defined $authn->{ 'Password' },                 'Check password not defined' );
ok( defined $authn->{ 'Response' },                   'Check response defined' );

$authn->set_results( 'Test Message', undef );
ok( $authn->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $authn->{ 'Response' },        'Check response no longer defined' );

$sling->{'User'} = 'testuser';
$sling->{'Auth'} = 'advanced';
$sling->{'Referer'} = '/test/referer';
$authn = new Apache::Sling::Authn(\$sling);
isa_ok $authn, 'Apache::Sling::Authn', 'authn';
ok( $authn->{ 'Type' }     eq 'advanced', 'Check Auth type set' );
ok( $authn->{ 'Username' } eq 'testuser', 'Check Auth user set' );

$authn->{'BaseURL'} = undef;
ok( ! defined $authn->{ 'BaseURL' }, 'Check base URL not defined' );
ok( $authn->login_user, 'Check login user returns fine with no base URL set');

throws_ok { $authn->switch_user } qr/New username to switch to not defined/, 'Check switch_user function croaks without new username';
throws_ok { $authn->switch_user('new_username') } qr/New password to use in switch not defined/, 'Check switch_user function croaks without new password';
