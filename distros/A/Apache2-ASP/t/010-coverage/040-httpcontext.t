#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
my $api; BEGIN { $api = Apache2::ASP::API->new }

can_ok( $api, 'config' );
ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );


# HandlerResolver that fails:
{
  local $api->config->web->{handler_resolver} = 'My::BadHandlerResolver';
  
  local $SIG{__WARN__} = sub { };
  $api->ua->get( '/index.asp' );
  like $api->context->server->GetLastError,
    qr/TEST ERROR/,
    'Bad resolver throws error';
}


# DoDisableSessionState on a location equals:
{
  local $api->config->web->{disable_persistence}->{location} = [
    Apache2::ASP::ConfigNode->new({
      uri_equals => '/index.asp',
      uri_match => undef,
      disable_session => 1,
      disable_application => 1,
    })
  ];
  $api->ua->get( '/index.asp' );
}


# FailFilter:
{
  local $api->config->web->{request_filters}->{filter} = [
    Apache2::ASP::ConfigNode->new({
      uri_match   => '/index\.asp',
      uri_equals  => undef,
      class       => 'My::FailFilter',
    })
  ];
  $api->ua->get( '/index.asp' );
}



# Swap out the global_asa:
{
  local $api->context->{global_asa} = '';
  $api->ua->get( '/index.asp' );
}




