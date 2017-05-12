#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::GroupMember' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn = new Apache::Sling::Authn(\$sling);
throws_ok { my $group_member = new Apache::Sling::GroupMember() } qr/no authn provided!/, 'Check creating group croaks without authn provided';
my $group_member = new Apache::Sling::GroupMember(\$authn,'1','log.txt');

ok( $group_member->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $group_member->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $group_member->{ 'Message' } eq '',                      'Check Message set' );
ok( $group_member->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $group_member->{ 'Authn' },                      'Check authn defined' );
ok( defined $group_member->{ 'Response' },                   'Check response defined' );

throws_ok { $group_member->add() } qr/No group name defined to add to!/, 'Check add function croaks without group specified';
throws_ok { $group_member->del() } qr/No group name defined to delete from!/, 'Check delete function croaks without group specified';
throws_ok { $group_member->check_exists() } qr/No group to view defined!/, 'Check exists function croaks without group specified';
throws_ok { $group_member->view() } qr/No group to view defined!/, 'Check view function croaks without group specified';

my $file = "\n";
throws_ok { $group_member->add_from_file() } qr/File to upload from not defined/, 'Check add_from_file function croaks without file';
throws_ok { $group_member->add_from_file(\$file) } qr/First CSV column must be the group ID, column heading must be "group". Found: ""./, 'Check add_from_file function croaks with blank file';
throws_ok { $group_member->add_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check add_from_file function croaks with non-existent file specified';


ok( my $group_member_config = Apache::Sling::GroupMember->config($sling), 'check config function' );
ok( Apache::Sling::GroupMember->run($sling,$group_member_config), 'check run function' );
throws_ok { Apache::Sling::GroupMember->run() } qr/No group_member config supplied!/, 'check run function croaks with no config supplied';
