#!perl

use strict;
use warnings;

use lib qw(t/lib inc);
use Test::More;

BEGIN {
    $ENV{TESTAPP_CONFIG_LOCAL_SUFFIX} = 'perlbal';
}

eval { use Test::WWW::Mechanize::Catalyst 'TestApp'; };
plan $@
  ? ( skip_app => 'Test::WWW:Mechanize::Catalyst required' )
  : ( tests => 8 );

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Create mechanize object' );

$mech->get_ok( 'http://localhost/test/view/sendfile',
    'request sendfile action' );
like( $mech->response->header('X-REPROXY-FILE'),
    qr/DUMMY/i, 'X-REPROXY-FILE header test' );

$mech->get_ok( 'http://localhost/test/view/proxy_file',
    'request reproxy_file action' );
like( $mech->response->header('X-REPROXY-FILE'),
    qr/DUMMY/i, 'X-REPROXY-FILE header test' );

$mech->get_ok( 'http://localhost/test/view/proxy_url',
    'request reproxy_url action' );
like( $mech->response->header('x-reproxy-url'),
    qr/DUMMY1/i, 'X-REPROXY-URL header test' );
like( $mech->response->header('x-reproxy-url'),
    qr/DUMMY2/i, 'X-REPROXY-URL header test' );
