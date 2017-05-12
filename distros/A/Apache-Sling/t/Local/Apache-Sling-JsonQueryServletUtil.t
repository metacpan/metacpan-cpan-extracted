#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling::JsonQueryServletUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );
ok( Apache::Sling::JsonQueryServletUtil::all_nodes_setup( 'http://localhost:8080') eq
  'get http://localhost:8080/content.query.json?queryType=xpath&statement=//*', 'Check all_nodes_setup function' );
throws_ok { Apache::Sling::JsonQueryServletUtil::all_nodes_setup() } qr/No base url defined!/, 'Check all_nodes_setup function croaks without base url';
ok( Apache::Sling::JsonQueryServletUtil::all_nodes_eval( \$res ), 'Check all_nodes_eval function' );
