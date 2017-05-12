#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn   = new Apache::Sling::Authn(\$sling);
my $user = new Apache::Sling::User(\$authn,'1','log.txt');
ok( $user->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $user->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $user->{ 'Message' } eq '',                      'Check Message set' );
ok( $user->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $user->{ 'Authn' },                      'Check authn defined' );
ok( defined $user->{ 'Response' },                   'Check response defined' );

$user->set_results( 'Test Message', undef );
ok( $user->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $user->{ 'Response' },          'Check response no longer defined' );

throws_ok { $user->add() } qr/No user name defined to add!/, 'Check add function croaks without user specified';
throws_ok { $user->change_password() } qr/No user name defined to change password for!/, 'Check check_exists function croaks without user specified';
throws_ok { $user->check_exists() } qr/No user to check existence of defined!/, 'Check check_exists function croaks without user specified';
throws_ok { $user->del() } qr/No user name defined to delete!/, 'Check del function croaks without user specified';
throws_ok { $user->update() } qr/No user name defined to update!/, 'Check update function croaks without user specified';
throws_ok { $user->view() } qr/No user to check existence of defined!/, 'Check view function croaks without user specified';
my $file = "\n";
throws_ok { $user->add_from_file() } qr/File to upload from not defined/, 'Check add_from_file function croaks without file specified';
throws_ok { $user->add_from_file(\$file) } qr/First CSV column must be the user ID, column heading must be "user". Found: ""./, 'Check add_from_file function croaks with blank file';
throws_ok { $user->add_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check add_from_file function croaks with non-existent file specified';

ok( my $user_config = Apache::Sling::User->config($sling), 'check config function' );
ok( Apache::Sling::User->run($sling,$user_config), 'check run function' );
throws_ok { Apache::Sling::User->run() } qr/No user config supplied!/, 'check run function croaks with no config supplied';
