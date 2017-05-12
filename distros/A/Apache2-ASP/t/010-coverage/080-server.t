#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
use HTTP::Date 'time2str';
my $api; BEGIN { $api = Apache2::ASP::API->new }

can_ok( $api, 'config' );
ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );

$api->ua->get('/index.asp');


# URLEncode:
{
  is(
    $api->context->server->URLEncode(' ') => '%20',
  );
}


# URLDecode:
{
  is(
    $api->context->server->URLDecode( ) => undef
  );
  is(
    $api->context->server->URLDecode('%20') => ' '
  );
  is(
    $api->context->server->URLDecode('%u0021') => '!'
  );
  is(
    $api->context->server->URLDecode('%u003C') => '<'
  );
}


# HTMLEncode:
{
  is(
    $api->context->server->HTMLEncode('<b>') => '&lt;b&gt;'
  );
}


# HTMLDecode:
{
  is(
    $api->context->server->HTMLDecode('&lt;b&gt;') => '<b>'
  );
}


# MapPath:
{
  is(
    $api->context->server->MapPath('/index.asp') =>
    $api->context->config->web->www_root . '/index.asp'
  );
}







