#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
my $api; BEGIN { $api = Apache2::ASP::API->new }

can_ok( $api, 'config' );
ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );

$api->ua->get('/index.asp');


# Cookies:
{
  ok(
    $api->context->request->Cookies,
    'request.cookies'
  );
  ok(
    $api->context->request->Cookies('session-id'),
    'request.cookies(session-id)'
  );
}


# QueryString:
{
  $api->ua->get('/index.asp?foo=bar');
  is(
    $api->context->request->QueryString => 'foo=bar',
    'request.querystring'
  );
}


# Form:
{
  $api->ua->get('/index.asp?foo=bar');

  is(
    $api->context->request->Form->{foo} => 'bar',
    'request.form'
  );
}



# ServerVariables:
{
  ok(
    my $host = $api->context->request->ServerVariables('HTTP_HOST'),
    'Got HTTP_HOST'
  );
  is(
    $host => $api->context->request->ServerVariables->{HTTP_HOST},
    'Request.ServerVariables can return hashref or single value'
  );
}






