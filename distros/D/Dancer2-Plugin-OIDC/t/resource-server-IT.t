#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use Plack::Test;
use HTTP::Request::Common;
use Test::More;
use Test::MockModule;

local $ENV{MOJO_LOG_LEVEL} = 'error';

local @ARGV = ('version');
my $provider_app = require "$Bin/auth-code-flow-IT/MyProviderApp.pl";

my $mock_oidc_client = Test::MockModule->new('OIDC::Client');
$mock_oidc_client->redefine('user_agent' => $provider_app->ua);

my $mock_crypt_jwt = Test::MockModule->new('Crypt::JWT');
$mock_crypt_jwt->redefine('decode_jwt' => sub {
  my %params = @_;
  my %claims = $params{token} eq 'Doe'
                 ? (iss       => 'my_issuer',
                    exp       => 12345,
                    aud       => 'my_id',
                    sub       => 'DOEJ',
                    firstName => 'John',
                    lastName  => 'Doe',
                    roles     => [qw/app.role1 app.role2/])
             : $params{token} eq 'Smith'
                 ? (iss       => 'my_issuer',
                    exp       => 12345,
                    aud       => 'my_id',
                    sub       => 'SMITHL',
                    firstName => 'Liam',
                    lastName  => 'Smith',
                    roles     => [qw/app.role3/])
             : die 'invalid token';
  return (
    $params{decode_header} ? {} : (),
    \%claims,
  );
});

use lib "$Bin/resource-server-IT";
use_ok('MyTestApp');
my $test = Plack::Test->create( MyTestApp->to_app );

subtest 'Get resource - unknown user' => sub {
  my $res = $test->request(GET '/my-resource',
                           Authorization => 'Bearer Unknown');
  is($res->code, 401, 'Error in response');
  is($res->content, '{"error":"Unauthorized"}', 'Expected response content');
};

subtest 'Get resource - user with insufficient roles' => sub {
  my $res = $test->request(GET '/my-resource',
                           Authorization => 'Bearer Smith');
  is($res->code, 403, 'Expected error code');
  is($res->content, '{"error":"Forbidden"}', 'Expected response content');
};

subtest 'Get resource - known user with sufficient roles' => sub {
  my $res = $test->request(GET '/my-resource',
                           Authorization => 'Bearer Doe');
  is($res->code, 200, 'Expected code');
  is($res->content, '{"user_login":"DOEJ"}', 'Expected response content');
};

done_testing;
