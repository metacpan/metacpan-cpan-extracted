#!/usr/bin/env perl

use v5.10;
use Azure::AD::DeviceLogin;

my $auth = Azure::AD::DeviceLogin->new(
  resource_id => 'https://graph.windows.net/',
  message_handler => sub {
    my $message = shift;
    say $message;
  },
);

use HTTP::Tiny;

my $ua = HTTP::Tiny->new;

my $response = $ua->get(
  'https://graph.windows.net/me?api-version=1.6',
  {
    headers => { 'Authorization' => 'Bearer ' . $auth->access_token },
  }
);

say $response->{ content };

