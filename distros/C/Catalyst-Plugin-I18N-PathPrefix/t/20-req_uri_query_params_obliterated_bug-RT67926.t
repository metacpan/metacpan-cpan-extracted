#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use HTTP::Request::Common;
use Catalyst::Test 'TestApp';

{
  my ($response, $c) = ctx_request(GET '/en/foo/bar?baz=1&quux=2');

  ok(
    $response->is_success,
    "The request was successful"
  );

  cmp_deeply(
    {
      $c->req->uri_with({ quuux => 3 })->query_form,
    },
    {
      baz   => 1,
      quux  => 2,
      quuux => 3,
    },
    "query params are not obliterated (RT67926)"
  );
}

done_testing;
