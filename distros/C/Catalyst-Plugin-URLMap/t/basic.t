#!/usr/bin/env perl

use FindBin;
use Test::Most;
use HTTP::Request::Common;

use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

ok my($res, $c) = ctx_request('/');

{
  ok my $response = request GET $c->uri_for_action('/welcome'),
    'got welcome from a catalyst controller';

  is $response->content, 'Welcome to Catalyst',
    'expected content body';
}

{
  ok my $response = request GET $c->uri_for('/hello-world'),
    'got hello-world response';

  is $response->content, 'hello world',
    'expected content body';
}

{
  ok my $response = request GET $c->uri_for('/dog'),
    'got a dog';

  is $response->content_type, 'image/jpeg',
    'is an image of a dog';
}

{
  ok my $response = request GET $c->uri_for('/static/message.txt'),
    'got a dog';

  like $response->content, qr/static message/,
    'got expected content';
}

{
  ok my $response = request GET $c->uri_for('/custom'),
    'got a dog';

  is $response->content, 'custom',
    'got expected content';
}

{
  ok my $response = request GET $c->uri_for('/deep/one'),
    'got a dog';

  is $response->content, 'one',
    'got expected content';
}

{
  ok my $response = request GET $c->uri_for('/deep/two'),
    'got a dog';

  is $response->content, 'two',
    'got expected content';
}

done_testing;
