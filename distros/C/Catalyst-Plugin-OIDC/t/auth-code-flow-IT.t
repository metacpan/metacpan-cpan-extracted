#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::MockModule;
use HTTP::Request::Common;
use HTTP::Cookies;

use FindBin qw($Bin);
use lib "$Bin/lib/MyCatalystApp/lib";

local $ENV{MOJO_LOG_LEVEL} = 'error';

my $provider_app = require "$Bin/lib/MyProviderApp/app.pl";

my $mock_oidc_client = Test::MockModule->new('OIDC::Client');
$mock_oidc_client->redefine('kid_keys' => sub { {} });
$mock_oidc_client->redefine('user_agent' => $provider_app->ua);

my $mock_plugin = Test::MockModule->new('OIDC::Client::Plugin');
$mock_plugin->redefine('_generate_uuid_string' => sub { 'fake_uuid' });

require Catalyst::Test;
Catalyst::Test->import('MyCatalystApp');

subtest 'Get public index page' => sub {
  my $res = request('/');
  ok($res->is_success, 'Status in success');
  like( $res->content, qr/Welcome/, 'Expected text');
};

subtest 'Get protected page in error because invalid token format' => sub {
  my $res = request('/protected');
  ok($res->is_redirect, 'Response is a redirect');
  like($res->header('Location'), qr[/authorize\?.+], 'Redirection to the authorize endpoint');
  $res = follow_redirects($res);
  is($res->code, 401, 'Expected error code');
  is($res->content, 'Authentication Error', 'Expected error message');
};

$mock_oidc_client->redefine('decode_jwt' => sub {
  {
    'iss'   => 'my_issuer',
    'exp'   => time + 30,
    'aud'   => 'my_id',
    'sub'   => 'my_subject',
    'nonce' => 'fake_uuid',
  }
});

subtest 'Get protected page ok' => sub {
  my $res = request('/protected?a=b&c=d');
  ok($res->is_redirect, 'Response is a redirect');
  like($res->header('Location'), qr[/authorize\?.+], 'Redirection to the authorize endpoint');
  $res = follow_redirects($res);
  ok($res->is_success, 'Status in success');
  like($res->content, qr/my_subject is authenticated/, 'Expected text');
  like($res->request->uri, qr[/protected\?a=b&c=d$],
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
    $res = request($req);
  }

  return $res;
}
