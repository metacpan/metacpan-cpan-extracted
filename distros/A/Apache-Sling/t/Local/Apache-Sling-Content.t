#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn   = new Apache::Sling::Authn(\$sling);
throws_ok { my $content = new Apache::Sling::Content() } qr/no authn provided!/, 'Check creating content croaks without authn provided';
my $content = new Apache::Sling::Content(\$authn,'1','log.txt');
ok( $content->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $content->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $content->{ 'Message' } eq '',                      'Check Message set' );
ok( $content->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $content->{ 'Authn' },                      'Check authn defined' );
ok( defined $content->{ 'Response' },                   'Check response defined' );

$content->set_results( 'Test Message', undef );
ok( $content->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $content->{ 'Response' },          'Check response no longer defined' );
throws_ok { $content->add() } qr/No position or ID to perform action for specified!/, 'Check add function croaks without remote_dest specified';
throws_ok { $content->copy() } qr/No content source to copy from defined!/, 'Check copy function croaks without remote_src specified';
throws_ok { $content->del() } qr/No content destination to delete defined!/, 'Check del function croaks without remote_dest specified';
throws_ok { $content->check_exists() } qr/No position or ID to perform exists for specified!/, 'Check check_exists function croaks without remote_dest specified';
throws_ok { $content->move() } qr/No content source to move from defined!/, 'Check move function croaks without remote_src specified';
throws_ok { $content->upload_file() } qr/No local file to upload defined!/, 'Check upload_file function croaks without file specified';
throws_ok { $content->view() } qr/No position or ID to perform exists for specified!/, 'Check view function croaks without remote_dest specified';
throws_ok { $content->view_file() } qr/No file to view specified!/, 'Check view_file function croaks without remote_dest specified';
my $file = "\n";
throws_ok { $content->upload_from_file() } qr/File to upload from not defined/, 'Check upload_from_file function croaks without file specified';
throws_ok { $content->upload_from_file(\$file) } qr/Problem parsing content to add/, 'Check upload_from_file function croaks with blank file';
throws_ok { $content->upload_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check upload_from_file function croaks with non-existent file specified';

ok( my $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
ok( Apache::Sling::Content->run($sling,$content_config), 'check run function' );
throws_ok { Apache::Sling::Content->run() } qr/No content config supplied!/, 'check run function croaks with no config supplied';
