#!/usr/bin/env perl

use v5.10;
use Azure::AD::Password;
use HTTP::Tiny;

my $user = $ENV{ AD_USERNAME } or die "Set env AD_USERNAME";
my $pass = $ENV{ AD_PASSWORD } or die "Set env AD_PASSWORD";

my $auth = Azure::AD::Password->new(
  resource_id => 'https://graph.windows.net/',
  username => $user,
  password => $pass,
);

my $ua = HTTP::Tiny->new;

my $response = $ua->get(
  'https://graph.windows.net/me?api-version=1.6',
  {
    headers => { 'Authorization' => 'Bearer ' . $auth->access_token },
  }
);

say $response->{ content };

