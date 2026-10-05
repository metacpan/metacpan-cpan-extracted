#!/usr/bin/env perl

# Airlock in a Mojolicious application.
#
#   perl -Ilib -Iexamples/lib examples/mojo.pl daemon -l http://*:5000
#   perl -Ilib examples/login.pl          # in a second terminal
#
# There is no plugin: the two machine endpoints are one route that hands the
# request to respond, and the approval page is an ordinary action.

use Mojolicious::Lite;
use Airlock::QR;
use AirlockExample::Demo;

my $demo = AirlockExample::Demo->new;

post '/airlock/:route' => [ route => [qw( device token )] ] => sub {
  my ( $c ) = @_;
  my ( $status, $headers, $json ) = @{ $demo->airlock->respond(
    'POST', $c->req->url->path->to_string, scalar $demo->airlock->parse_form( $c->req->body ),
    { ip => $c->tx->remote_address, ua => $c->req->headers->user_agent }
  ) };
  $c->res->headers->header( $_ => $headers->{$_} ) for keys %$headers;
  $c->render( json => $json, status => $status );
};

any [qw( GET POST )] => '/approve' => sub {
  my ( $c ) = @_;
  my $param = $c->req->method eq 'POST' ? $c->req->body_params : $c->req->query_params;
  my ( $status, $html ) = $demo->page( method => $c->req->method, map { $_ => scalar $param->param($_) } qw( user_code action pin ) );
  $c->res->headers->cache_control('no-store');
  $c->render( data => $html, format => 'html', status => $status );
};

get '/qr' => sub {
  my ( $c ) = @_;
  my $view = $demo->airlock->inspect( $c->param('user_code') ) or return $c->render( text => 'unknown code', status => 404 );
  my $uri = $demo->airlock->verification_uri.'?user_code='.$view->{user_code};
  $c->render( data => Airlock::QR->new( text => $uri )->svg, format => 'svg' );
};

app->start;
