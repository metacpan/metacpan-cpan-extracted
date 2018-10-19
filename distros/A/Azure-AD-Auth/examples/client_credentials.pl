#!/usr/bin/env perl

use v5.10;
use Azure::AD::ClientCredentials;

my $auth = Azure::AD::ClientCredentials->new(
  resource_id => 'https://graph.windows.net/',
);

say $auth->access_token;
