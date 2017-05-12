#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling::ContentUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );
my @properties = '';

ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  'post http://localhost:8080/remote/ $post_variables = []', 'Check add_setup function' );
push @properties, "a=b";
ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  "post http://localhost:8080/remote/ \$post_variables = ['a','b']", 'Check add_setup function with variables' );
throws_ok { Apache::Sling::ContentUtil::add_setup() } qr/No base URL provided!/, 'Check add_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080' ) } qr/No position or ID to perform action for specified!/, 'Check add_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::add_eval( \$res ), 'Check add_eval function' );

ok( Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','copy']", 'Check copy_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','copy',':replace','true']", 'Check copy_setup function with replace defined' );
throws_ok { Apache::Sling::ContentUtil::copy_setup() } qr/No base url defined!/, 'Check copy_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::copy_setup( 'http://localhost:8080' ) } qr/No content source to copy from defined!/, 'Check copy_setup function croaks without remote_src';
throws_ok { Apache::Sling::ContentUtil::copy_setup( 'http://localhost:8080','remoteSrc/' ) } qr/No content destination to copy to defined!/, 'Check copy_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::copy_eval( \$res ), 'Check copy_eval function' );

ok(Apache::Sling::ContentUtil::delete_setup('http://localhost:8080','remote/') eq
  "post http://localhost:8080/remote/ \$post_variables = [':operation','delete']", 'Check delete_setup function' );
throws_ok { Apache::Sling::ContentUtil::delete_setup() } qr/No base url defined!/, 'Check delete_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::delete_setup('http://localhost:8080') } qr/No content destination to delete defined!/, 'Check delete_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::delete_eval( \$res ), 'Check delete_eval function' );

ok(Apache::Sling::ContentUtil::exists_setup('http://localhost:8080','remote') eq
  "get http://localhost:8080/remote.json", 'Check exists_setup function' );
throws_ok { Apache::Sling::ContentUtil::exists_setup() } qr/No base url defined!/, 'Check exists_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::exists_setup('http://localhost:8080') } qr/No position or ID to perform exists for specified!/, 'Check exists_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::exists_eval( \$res ), 'Check exists_eval function' );

ok(Apache::Sling::ContentUtil::full_json_setup('http://localhost:8080','remote') eq "get http://localhost:8080/remote.infinity.json", 'Check full_json_setup function' );
throws_ok { Apache::Sling::ContentUtil::full_json_setup() } qr/No base url defined!/, 'Check full_json_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::full_json_setup('http://localhost:8080')
} qr/No position or ID to retrieve full json for specified!/, 'Check full_json_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::full_json_eval( \$res ), 'Check full_json_eval function' );

ok( Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','move']", 'Check move_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','move',':replace','true']", 'Check move_setup function with replace defined' );
throws_ok { Apache::Sling::ContentUtil::move_setup() } qr/No base url defined!/, 'Check move_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::move_setup('http://localhost:8080') } qr/No content source to move from defined!/, 'Check move_setup function croaks without remote_src';
throws_ok { Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/') } qr/No content destination to move to defined!/, 'Check move_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::move_eval( \$res ), 'Check move_eval function' );

ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','') eq
  "fileupload http://localhost:8080/remote ./* ./local \$post_variables = []", 'Check upload_file_setup function' );
ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','file') eq
  "fileupload http://localhost:8080/remote file ./local \$post_variables = []", 'Check upload_file_setup function' );
throws_ok { Apache::Sling::ContentUtil::upload_file_setup() } qr/No base URL provided to upload against!/, 'Check upload_file_setup function croaks without base url';
throws_ok { Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080') } qr/No local file to upload defined!/, 'Check upload_file_setup function croaks without local_path';
throws_ok { Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','local') } qr/No remote path to upload to defined for file local!/, 'Check upload_file_setup function croaks without remote_dest';
ok( Apache::Sling::ContentUtil::upload_file_eval( \$res ), 'Check upload_file_eval function' );
