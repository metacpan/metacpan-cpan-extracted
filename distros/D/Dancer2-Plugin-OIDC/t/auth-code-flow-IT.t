#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Plack::Test;
use Test::More;
use Test::MockModule;
use HTTP::Request::Common;
use HTTP::Cookies;
use FindBin qw($Bin);

local $ENV{MOJO_LOG_LEVEL} = 'error';

local @ARGV = ('version');
my $provider_app = require "$Bin/auth-code-flow-IT/MyProviderApp.pl";

my $mock_oidc_client = Test::MockModule->new('OIDC::Client');
$mock_oidc_client->redefine('user_agent' => $provider_app->ua);

my $mock_data_uuid = Test::MockModule->new('Data::UUID');
$mock_data_uuid->redefine('create_str' => sub { 'fake_uuid' });

use lib "$Bin/auth-code-flow-IT";
use_ok('MyTestApp');
my $test = Plack::Test->create( MyTestApp->to_app );

subtest 'Get public index page' => sub {
  my $res = $test->request( GET '/');
  ok($res->is_success, 'Status in success');
  like( $res->content, qr/Welcome/, 'Expected text');
};

subtest 'Get protected page in error because invalid token format' => sub {
  my $res = $test->request( GET '/protected' );
  ok( $res->is_redirect, 'Response is a redirect' );
  like( $res->header('Location'), qr[/authorize\?.+], 'redirection to the authorize endpoint' );
  $res = follow_redirects($res);
  is( $res->code, 401, 'Error in response' );
  is( $res->content, 'Authentication Error', 'Correct response content' );
};

my $mock_crypt_jwt = Test::MockModule->new('Crypt::JWT');
$mock_crypt_jwt->redefine('decode_jwt' => sub {
  my %params = @_;
  my %claims = (
    iss   => 'my_issuer',
    iat   => time - 10,
    exp   => time + 30,
    aud   => 'my_id',
    sub   => 'my_subject',
    nonce => 'fake_uuid',
  );
  return (
    $params{decode_header} ? { 'alg' => 'whatever' } : (),
    \%claims,
  );
});

subtest 'Get protected page ok' => sub {
  my $res = $test->request( GET '/protected?a=b&c=d' );
  ok( $res->is_redirect, 'Response is a redirect' );
  like( $res->header('Location'), qr[/authorize\?.+], 'redirection to the authorize endpoint' );
  $res = follow_redirects($res);
  ok( $res->is_success, 'Successful request' );
  is( $res->content, 'my_subject is authenticated', 'Correct response content' );
  like($res->request->uri, qr[/protected\?(a=b&c=d)|(c=d&a=b)$],
       'Initial url is kept');
};

done_testing;

sub follow_redirects {
  my ($res, $max_redirects) = @_;
  $max_redirects //= 3;

  my $cookie_jar = HTTP::Cookies->new;
  $cookie_jar->extract_cookies($res);

  my $i = 0;
  while ($res->is_redirect && ++$i <= $max_redirects) {
    my $req = GET $res->header('Location');
    $cookie_jar->add_cookie_header($req);
    $res = $test->request($req);
  }

  return $res;
}
