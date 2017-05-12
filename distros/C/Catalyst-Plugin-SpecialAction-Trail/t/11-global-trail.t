#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use HTTP::Request::Common;
use Catalyst::Test 'TestAppWithGlobalTrail';

{
  my ($response, $c) = ctx_request(
    GET '/foo/quux'
  );

  ok(
    $response->is_success,
    "The request was successful"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestAppWithGlobalTrail::Controller::Foo::quux',
      'TestAppWithGlobalTrail::Controller::Root::trail',
      'TestAppWithGlobalTrail::Controller::Foo::trail',
      'TestAppWithGlobalTrail::Controller::Foo::end',
    ],
    "'trail' is called"
  );
}

done_testing;
