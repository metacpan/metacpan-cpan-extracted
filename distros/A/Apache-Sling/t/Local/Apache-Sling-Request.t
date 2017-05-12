#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Request' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

my $sling = Apache::Sling->new();
my $authn = new Apache::Sling::Authn(\$sling);
my $content = new Apache::Sling::Content(\$authn,'1','log.txt');
throws_ok { Apache::Sling::Request::string_to_request() } qr/No string defined to turn into request!/, 'Checking string_to_request function string undefined';
throws_ok { Apache::Sling::Request::string_to_request('',\$authn) } qr/Error generating request for blank target!/, 'Checking string_to_request function blank string';
ok ( Apache::Sling::Request::string_to_request("post http://localhost:8080 \$post_variables = ['a','b']",\$authn), 'Checking string_to_request function for post action' );
ok ( Apache::Sling::Request::string_to_request("data http://localhost:8080 \$post_variables = ['a','b']",\$authn), 'Checking string_to_request function for data action' );
my ( $tmp_print_file_handle, $tmp_print_file_name ) = File::Temp::tempfile();
ok ( Apache::Sling::Request::string_to_request("fileupload http://localhost:8080 filename $tmp_print_file_name \$post_variables = []",\$authn), 'Checking string_to_request function for file upload action' );
throws_ok { Apache::Sling::Request::string_to_request("fileupload http://localhost:8080 filename $tmp_print_file_name \$post_variables = ['a',",\$authn) } qr//, 'Checking string_to_request function for fileupload action fails with broken post variables';
unlink($tmp_print_file_name);
$authn->{'Username'} = 'user';
$authn->{'Password'} = 'pass';
ok ( Apache::Sling::Request::string_to_request("put http://localhost:8080",\$authn), 'Checking string_to_request function for put action' );
ok ( Apache::Sling::Request::string_to_request("delete http://localhost:8080",\$authn), 'Checking string_to_request function for delete action' );
$authn->{'Verbose'} = 2;
ok ( Apache::Sling::Request::string_to_request("get http://localhost:8080",\$authn), 'Checking string_to_request function for get action' );
throws_ok { Apache::Sling::Request::request(\$content,'') } qr/Error generating request for blank target!/, 'Checking request function blank string';
throws_ok { Apache::Sling::Request::request() } qr/No reference to a suitable object supplied!/, 'Check request function croaks without object';
throws_ok { Apache::Sling::Request::request(\$content) } qr/No string defined to turn into request!/, 'Check request function croaks without string';
throws_ok { Apache::Sling::Request::string_to_request("post http://localhost:8080 \$post_variables = ['a',",\$authn) } qr//, 'Checking string_to_request function for post action fails with broken post variables';
throws_ok { Apache::Sling::Request::string_to_request("data http://localhost:8080 \$post_variables = ['a',",\$authn) } qr//, 'Checking string_to_request function for data action fails with broken post variables';
$authn->{'LWP'} = undef;
throws_ok { Apache::Sling::Request::string_to_request("post http://localhost:8080 \$post_variables = ['a','b']",\$authn) } qr//, 'Checking string_to_request function for post action fails without LWP defined';
