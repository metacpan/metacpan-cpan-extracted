#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'Mojolicious is needed for this example'
    unless eval { require Test::Mojo; require Mojo::File; 1 };
}

my $t     = Test::Mojo->new( Mojo::File->new('examples/mojo.pl') );
my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

$t->post_ok( '/airlock/device' => form => { client_id => 'demo-cli', scope => 'read admin' } )
  ->status_is(200)->header_is( 'Cache-Control' => 'no-store' )->json_has('/device_code')->json_like( '/user_code' => qr/\A\w{4}-\w{4}\z/ );
my $start = $t->tx->res->json;

$t->post_ok( '/airlock/token' => form => { grant_type => $grant, client_id => 'demo-cli', device_code => $start->{device_code} } )
  ->status_is(400)->json_is( '/error' => 'authorization_pending' );

$t->post_ok( '/airlock/device' => { 'Content-Type' => 'application/x-www-form-urlencoded' } => 'client_id=demo-cli&client_id=other' )
  ->status_is(400)->json_is( '/error' => 'invalid_request', 'a repeated parameter is refused, as with to_app' );

$t->get_ok( '/approve' => form => { user_code => $start->{user_code} } )
  ->status_is(200)->content_like(qr/Demo CLI/)->content_like(qr/name="pin"/);

$t->get_ok( '/approve' => form => { user_code => $start->{user_code}, action => 'approve', pin => '4711' } )
  ->status_is(200)->content_unlike( qr/Approved/, 'opening a link approves nothing' );

$t->post_ok( '/approve' => form => { user_code => $start->{user_code}, action => 'approve', pin => '4711' } )
  ->status_is(200)->content_like(qr/Approved/);

$t->get_ok( '/qr' => form => { user_code => 'ZZZZ-ZZZZ' } )->status_is(404);

$t->post_ok( '/airlock/nope' => form => {} )->status_is(404);

done_testing;
