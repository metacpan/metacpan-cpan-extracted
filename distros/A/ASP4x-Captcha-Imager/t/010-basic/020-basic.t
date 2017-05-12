#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Digest::MD5 'md5_hex';
use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

ok(
  my $res = $api->ua->get('/handlers/dev.captcha'),
  "Got res"
);

ok(
  length($res->content),
  "Got res.content"
);

is(
  $res->header('content-type') => "image/png",
  "content-type is image/png"
);

my $Session = $api->context->session;

my $wordLength = $api->context->config->system->settings->captcha_length;
my $secret = $api->context->config->system->settings->captcha_key;

my ($word) = grep {
  length($_) == $wordLength &&
  md5_hex($_ . $secret) eq $Session->{asp4captcha}->{$_};
} keys %{ $Session->{asp4captcha} };

ok( $word, "Found word '$word'");

my $hashed = md5_hex($word . $secret);
is($hashed => $Session->{asp4captcha}->{$word}, "Hashing is correct" );


