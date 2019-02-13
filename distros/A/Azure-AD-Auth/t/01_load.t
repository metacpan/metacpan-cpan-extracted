#!/usr/bin/env perl

use Test::More;

use_ok('Azure::AD::ClientCredentials');
use_ok('Azure::AD::DeviceLogin');
use_ok('Azure::AD::Password');

{
  my $auth = Azure::AD::ClientCredentials->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    secret_id => 'sec1',
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.com|, 'Got default endpoint');
}

{
  my $auth = Azure::AD::ClientCredentials->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    secret_id => 'sec1',
    ad_url => 'https://login.microsoftonline.us',
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.us|, 'Got custom US endpoint');
}

{
  my $auth = Azure::AD::DeviceLogin->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    message_handler => sub { },
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.com|, 'Got default endpoint');
  like($auth->device_endpoint, qr|^https://login.microsoftonline.com|, 'Got default endpoint');
}

{
  my $auth = Azure::AD::DeviceLogin->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    message_handler => sub { },
    ad_url => 'https://login.microsoftonline.us',
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.us|, 'Got custom US endpoint');
  like($auth->device_endpoint, qr|^https://login.microsoftonline.us|, 'Got default endpoint');
}

{
  my $auth = Azure::AD::Password->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    username => 'user',
    password => 'pass',
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.com|, 'Got default endpoint');
}

{
  my $auth = Azure::AD::Password->new(
    resource_id => 'random',
    client_id => 'cid1',
    tenant_id => 'ten1',
    username => 'user',
    password => 'pass',
    ad_url => 'https://login.microsoftonline.us',
  );
  like($auth->token_endpoint, qr|^https://login.microsoftonline.us|, 'Got custom US endpoint');
}

done_testing;
