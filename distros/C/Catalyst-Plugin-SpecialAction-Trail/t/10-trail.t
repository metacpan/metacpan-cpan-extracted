#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use HTTP::Request::Common;
use Catalyst::Test 'TestApp';

{
  my ($response, $c) = ctx_request(
    GET '/foo/quux'
  );

  ok(
    $response->is_success,
    "The request was successful ('trail' not enabled in the controller)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::quux',
    ],
    "'trail' was not called ('trail' not enabled in the controller)"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/bar/quux'
  );

  ok(
    $response->is_success,
    "The request was successful (controller with 'trail' enabled)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Bar::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::trail',
      'TestApp::Controller::Foo::Bar::trail',
      'TestApp::Controller::Foo::Bar::end',
    ],
    "'trail' is called (controller with 'trail' enabled)"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/qux/quux'
  );

  ok(
    $response->is_success,
    "The request was successful (controller with 'trail' enabled, "
      . "no 'trail' method)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Qux::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::trail',
      'TestApp::Controller::Foo::Qux::end',
    ],
    "'trail' is called (controller with 'trail' enabled, no 'trail' method)"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/baz/quux'
  );

  ok(
    $response->is_success,
    "The request was successful (controller with 'trail' enabled, no 'end')"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Baz::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::trail',
      'TestApp::Controller::Foo::Baz::trail',
    ],
    "'trail' is called (controller with 'trail' enabled, no 'end')"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/bar/quux?Foo::Bar=0'
  );

  ok(
    $response->is_success,
    "The request was successful (self controller 'trail' returns 0)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Bar::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::trail',
      'TestApp::Controller::Foo::Bar::trail',
      'TestApp::Controller::Foo::Bar::end',
    ],
    "'trail' is called (self controller 'trail' returns 0)"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/bar/quux?Foo=0'
  );

  ok(
    $response->is_success,
    "The request was successful (parent controller 'trail' returns 0)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Bar::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::trail',
      'TestApp::Controller::Foo::Bar::end',
    ],
    "'trail' is called (parent controller 'trail' returns 0)"
  );
}

{
  my ($response, $c) = ctx_request(
    GET '/foo/bar/quux?Root=0'
  );

  ok(
    $response->is_success,
    "The request was successful (root controller 'trail' returns 0)"
  );

  eq_or_diff(
    $c->called_actions,
    [
      'TestApp::Controller::Foo::Bar::quux',
      'TestApp::Controller::Root::trail',
      'TestApp::Controller::Foo::Bar::end',
    ],
    "'trail' is called (root controller 'trail' returns 0)"
  );
}

done_testing;
