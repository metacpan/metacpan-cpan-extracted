#!/usr/bin/env perl

# Airlock in a Plack application.
#
#   plackup -Ilib -Iexamples/lib examples/app.psgi
#   perl -Ilib examples/login.pl          # in a second terminal
#
# The machine endpoints are mounted with to_app. The approval page is this
# application's own: it reads the request, asks Airlock, renders HTML.

use strict;
use warnings;
use Airlock::QR;
use AirlockExample::Demo;
use Plack::Builder;
use Plack::Request;

my $demo = AirlockExample::Demo->new;

my $approve = sub {
  my ( $env ) = @_;
  my $request = Plack::Request->new($env);
  my $param   = $request->method eq 'POST' ? $request->body_parameters : $request->query_parameters;
  my ( $status, $html ) = $demo->page( method => $request->method, map { $_ => scalar $param->get($_) } qw( user_code action pin ) );
  return [ $status, [ 'Content-Type' => 'text/html; charset=utf-8', 'Cache-Control' => 'no-store' ], [$html] ];
};

# The QR code a device without a terminal would show: it leads the phone to
# the approval page with the code filled in.
my $qr = sub {
  my ( $env ) = @_;
  my $view = $demo->airlock->inspect( Plack::Request->new($env)->query_parameters->get('user_code') )
    or return [ 404, [ 'Content-Type' => 'text/plain' ], ['unknown code'] ];
  my $uri = $demo->airlock->verification_uri.'?user_code='.$view->{user_code};
  return [ 200, [ 'Content-Type' => 'image/svg+xml', 'Cache-Control' => 'no-store' ], [ Airlock::QR->new( text => $uri )->svg ] ];
};

builder {
  mount '/airlock' => $demo->airlock->to_app;
  mount '/approve' => $approve;
  mount '/qr.svg'  => $qr;
};
