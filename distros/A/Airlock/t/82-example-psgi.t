#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'Plack is needed for this example'
    unless eval { require Plack::Test; require Plack::Util; require HTTP::Request::Common; 1 };
}

use JSON::MaybeXS;
use HTTP::Request::Common qw( GET POST );

my $app   = Plack::Util::load_psgi('examples/app.psgi');
my $test  = Plack::Test->create($app);
my $grant = 'urn:ietf:params:oauth:grant-type:device_code';

sub start {
  my ( $scope ) = @_;
  my $response = $test->request( POST '/airlock/device', [ client_id => 'demo-cli', scope => $scope ] );
  is( $response->code, 200, 'device endpoint' );
  return decode_json( $response->content );
}

sub poll {
  my ( $start ) = @_;
  my $response = $test->request( POST '/airlock/token', [ grant_type => $grant, client_id => 'demo-cli', device_code => $start->{device_code} ] );
  return decode_json( $response->content );
}

subtest 'plain scope: look, approve, token' => sub {
  my $start = start('read');
  is( poll($start)->{error}, 'authorization_pending', 'pending' );

  my $form = $test->request( GET '/approve' );
  like( $form->content, qr/name="user_code"/, 'without a code the page asks for one' );

  my $look = $test->request( GET '/approve?user_code='.$start->{user_code} );
  is( $look->code, 200, 'approval page' );
  like( $look->content, qr/<b>Demo CLI<\/b> wants access: read/, 'shows client and scopes' );
  unlike( $look->content, qr/name="pin"/, 'no PIN for a plain scope' );
  is( poll($start)->{error}, 'slow_down', 'looking approved nothing (and the second poll came too fast)' );

  my $done = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve' ] );
  like( $done->content, qr/Approved/, 'approved' );
  is( $test->request( GET '/approve?user_code='.$start->{user_code} )->code, 404, 'the code is used up' );
};

subtest 'step-up scope: PIN' => sub {
  my $start = start('read admin');
  like( $test->request( GET '/approve?user_code='.$start->{user_code} )->content, qr/name="pin"/, 'the page asks for the PIN' );
  my $wrong = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve', pin => '0000' ] );
  is( $wrong->code, 403, 'wrong PIN' );
  like( $wrong->content, qr/Wrong PIN/, 'says so' );
  my $right = $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'approve', pin => '4711' ] );
  like( $right->content, qr/Approved/, 'right PIN' );
};

subtest 'deny' => sub {
  my $start = start('read');
  like( $test->request( POST '/approve', [ user_code => $start->{user_code}, action => 'deny' ] )->content, qr/Denied/, 'denied' );
  is( poll($start)->{error}, 'access_denied', 'the device learns it' );
};

subtest 'unknown code and escaping' => sub {
  my $response = $test->request( GET '/approve?user_code=%3Cscript%3E' );
  is( $response->code, 404, 'unknown code' );
  unlike( $response->content, qr/<script>/, 'nothing typed is echoed' );
};

subtest 'qr' => sub {
  my $start = start('read');
  my $qr    = $test->request( GET '/qr.svg?user_code='.$start->{user_code} );
  is( $qr->code, 200, 'QR code' );
  is( $qr->header('Content-Type'), 'image/svg+xml', 'as SVG' );
  like( $qr->content, qr/\A<svg /, 'SVG body' );
  is( $test->request( GET '/qr.svg?user_code=ZZZZ-ZZZZ' )->code, 404, 'no QR code for an unknown code' );
};

subtest 'opening a link never approves or denies' => sub {
  my $start = start('read');
  my $get   = $test->request( GET '/approve?action=approve&user_code='.$start->{user_code} );
  is( $get->code, 200, 'the page is shown' );
  unlike( $get->content, qr/Approved/, 'but nothing is approved' );
  is( poll($start)->{error}, 'authorization_pending', 'the device keeps waiting' );
  unlike( $test->request( GET '/approve?action=deny&user_code='.$start->{user_code} )->content, qr/Denied/, 'nor denied by a link' );
  my $mixed = $test->request( POST '/approve?action=approve&user_code='.$start->{user_code}, [] );
  unlike( $mixed->content, qr/Approved/, 'an action in the query string of a POST does not count either' );
};

done_testing;
