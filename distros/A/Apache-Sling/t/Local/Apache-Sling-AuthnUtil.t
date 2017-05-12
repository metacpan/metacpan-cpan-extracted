#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling::AuthnUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

ok( Apache::Sling::AuthnUtil::basic_login_setup( 'http://localhost:8080' ) eq
  'get http://localhost:8080/system/sling/login?sling:authRequestLogin=1', 'Check basic_login_setup function' );
throws_ok { Apache::Sling::AuthnUtil::basic_login_setup() } qr/No base url defined!/, 'Check basic_login_setup function croaks without base url';
my $res = HTTP::Response->new( '200' );
ok( Apache::Sling::AuthnUtil::basic_login_eval( \$res ), 'Check basic_login_eval function' );
