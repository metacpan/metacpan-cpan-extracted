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



# Set Status after headers have been sent:
#{
#  eval {
#    $api->context->response->Status( 200 );
#  };
#  ok( $@, 'threw an exception' );
#  like
#    $@,
#    qr/Response\.Status cannot be changed after headers have been sent/,
#    'exception looks correct';
#  is(
#    $api->context->response->Status => 200
#  );
#}



# ContentType:
{
  local $api->context->{_did_send_headers};
  is( $api->context->response->ContentType => 'text/html' );
  ok( $api->context->response->ContentType('text/xhtml'), 'set content-type to text/xhtml' );
  is( $api->context->response->ContentType => 'text/xhtml' );
}



# Expires:
{
  local $api->context->{_did_send_headers};
  
  is( $api->context->response->Expires => 0, 'response.expires defaults to 0' );
  ok( my $orig_absolute = $api->context->response->ExpiresAbsolute, 'Got response.ExpiresAbsolute' );
  ok( $api->context->response->Expires( -5 ), 'Changed response.exires to -5' );
  is( $api->context->response->Expires => -5, 'response.expires changed to -5' );
  isnt( $api->context->response->ExpiresAbsolute, $orig_absolute, 'response.ExpiresAbsolute changed' );
}


# Redirect:
{
  local $api->context->{_did_send_headers};
  
  ok( my $val = $api->context->response->Redirect('/other.asp'), 'redirected' );
  is( $val => 302, 'response.redirect returns 302' );
  
  eval {
    $api->context->response->Redirect('/fail.asp');
  };
  ok( $@, 'respons.redirect again threw exception' );
  like $@,
        qr/Response\.Redirect cannot be called after headers have been sent/,
        'exception looks right';
}


# Include after the request ended:
{
  # Should NOT throw exception:
  eval {
    $api->context->response->Include( $api->context->server->MapPath('/inc.asp' ) );
  };
  ok( ! $@, 'no exception thrown' );
}


# TrapInclude(1):
{
  # Should NOT throw exception:
  eval {
    $api->context->response->TrapInclude( $api->context->server->MapPath('/inc.asp' ) );
  };
  ok( ! $@, 'no exception thrown' );
}


# TrapInclude(2):
{
  local $api->context->{did_end};
  ok(
    my $res = $api->context->response->TrapInclude( $api->context->server->MapPath('/inc.asp' ) ),
    'got response.trapinclude content'
  );
  like  $res,
        qr/\s+Included\! 1\:2\:3\:4\:5\:6\:7\:8\:9\:10\s+/,
        'TrapInclude content looks right';
}


# Cookies:
{
  is( $api->context->response->Cookies => undef, 'response.cookies starts out undef' );
  
  $api->context->response->AddCookie(
    'test-cookie' => '123'
  );
  like(
    $api->context->response->Cookies, qr/test\-cookie\=123; path\=\/; expires\=.*?\s+GMT/i,
    'response.Cookies looks right after adding a single cookie'
  );
  $api->context->response->AddCookie(
    'another-cookie' => 'foobar'
  );
  
  # Now we should have an arrayref of cookies:
  is(
    ref($api->context->response->Cookies) => 'ARRAY',
    'two cookies makes an array'
  );
  like(
    $api->context->response->Cookies->[0], qr/test\-cookie\=123; path\=\/; expires\=.*?\s+GMT/i,
    'The first cookie is in the first position'
  );
  like(
    $api->context->response->Cookies->[1], qr/another\-cookie\=foobar; path\=\/; expires\=.*?\s+GMT/i,
    'The second cookie is in the second position'
  );
  
  # Test out the other options:
  $api->context->response->AddCookie(
    'path-cookie' => 'pathtest' => '/path/'
  );
  like(
    $api->context->response->Cookies->[2], qr/path\-cookie\=pathtest; path\=\/path\/; expires\=.*?\s+GMT/i,
    'Path cookie looks right and is in the correct position'
  );
  my $five_minutes = time2str( time() + 300 );
  $api->context->response->AddCookie(
    'expire-cookie' => 'expiretest' => '/expires/' => time() + 300
  );
  is(
    $api->context->response->Cookies->[3], "expire-cookie=expiretest; path=/expires/; expires=$five_minutes",
    'Expiration cookie looks right and is in the correct position'
  );
  
}




# DeleteHeader:
{
  $api->context->response->AddHeader( 'removable' => 'test' );
  is( $api->context->response->Headers->{removable} => 'test' );
  $api->context->response->DeleteHeader( 'removable' );
  is( $api->context->response->Headers->{removable} => undef );
}


# IsClientConnected
{
  ok( ! $api->context->response->IsClientConnected, 'response.IsClientConnected is false' );
  local $api->context->{did_end};
  ok( $api->context->response->IsClientConnected, 'response.IsClientConnected is true' );
  
}


# AddHeader:
{
  $api->context->response->AddHeader( );
  $api->context->response->AddHeader( name => undef );
  $api->context->response->AddHeader( undef => undef );
  $api->context->response->AddHeader( undef => 'true' );
}




