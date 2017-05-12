#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

use_ok('ASP4x::Router');

# CreatePage:
my $res = $api->ua->get("/main/truck/create/");
is( $res->content => "CreatePage truck\n", "GET '/main/truck/create/' correct");

# Create handler:
$res = $api->ua->post("/main/truck/create/");
is( $res->content => "Create truck", "POST '/main/truck/create/' correct");

# List via GET
$res = $api->ua->get("/main/truck/list/");
is( $res->content => "List truck page 1\n", "GET '/main/truck/list/' correct");

$res = $api->ua->get("/main/truck/list/2/");
is( $res->content => "List truck page 2\n", "GET '/main/truck/list/2/' correct");

# List via POST
$res = $api->ua->post("/main/truck/list/");
is( $res->content => "List truck page 1\n", "POST '/main/truck/list/' correct");
$res = $api->ua->post("/main/truck/list/2/");
is( $res->content => "List truck page 2\n", "POST '/main/truck/list/2/' correct");

for( 3..300 )
{
  $res = $api->ua->get("/main/truck/list/$_/");
  is( $res->content => "List truck page $_\n", "GET '/main/truck/list/$_/' correct");
}# end for()

# View via GET
$res = $api->ua->get("/main/truck/1/");
is( $res->content => "View truck id 1\n", "GET '/main/truck/1/' correct");

# View via POST
$res = $api->ua->post("/main/truck/1/");
is( $res->content => "View truck id 1\n", "POST '/main/truck/1/' correct");

# EditPage
$res = $api->ua->get("/main/truck/1/edit/");
is( $res->content => "EditPage truck id 1\n", "GET '/main/truck/1/edit/' correct");

# Edit handler
$res = $api->ua->post("/main/truck/1/edit/");
is( $res->content => "Edit truck id 1", "POST '/main/truck/1/edit/' correct");

# Delete handler
$res = $api->ua->post("/main/truck/1/delete/");
is( $res->content => "Delete truck id 1", "POST '/main/truck/1/delete/' correct");


is(
  '/main/truck/create/' =>
  $api->context->config->web->router->uri_for('CreatePage', { type => 'truck' }),
  "Got router and uri_for(...) just fine."
);


EXTERNAL_ROUTES: {
  ok( my $res = $api->ua->get('/foo/foo/'), "GET /foo/foo/" );
  ok( $res->is_success, "/foo/foo/ was successful" );
  like $res->content => qr(You have reached foo.asp), "content looks right";
};


