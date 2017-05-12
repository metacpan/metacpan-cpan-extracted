#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test qw(TestApp);

my ( $res, $c );

( $res, $c ) = ctx_request( '/hello_world.asp' );
like( $res->content, qr/<h1>Hello World!<\/h1>/, 'Simple Hello World page processed!' );
unlike( $res->content, qr/extra content should not be seen/, '$Response->End properly' );
like( $c->res->header( 'Content-Type' ), qr/^TeXt\/HTml/, 'Content type successfully set' );
is( $c->res->content_type_charset,         'ISO-LATIN-1', 'Content type charset successfully set' );
is( $c->res->cookies->{gotcha}{value},     'yup!',        'Cookie successfully set' );
is( $c->res->cookies->{another}{value}[0], 'gotcha=yup!', 'Another cookie successfully set' );

content_like(
    '/welcome.asp',
    qr/<title>Welcome Page!<\/title>.*<p>This is the welcome page for TestApp::ASP<\/p>/s,
    'Welcome page fully processed with XMLSubs and $Response->Include!'
);

content_like(
    '/welcome_again.asp',
    qr/<h1>Welcome again to TestApp::ASP!<\/h1>/s,
    'Welcome again page fully processed, tested $Response->TrapInclude!'
);

( $res, $c ) = ctx_request( '/die.asp' );
is( $c->res->status, 500, 'Properly errored' );

action_notfound( '/notfound.asp',                 'Properly not found for non-existent file' );
action_notfound( '/templates/some_template.tmpl', 'Properly not found for templates, though in root' );

action_redirect( '/redirect.asp',           'Properly redirected' );
action_redirect( '/redirect_permanent.asp', 'Properly redirected manually' );
( $res, $c ) = ctx_request( '/redirect_permanent.asp' );
is( $c->res->status, 301, 'Properly permanently redirected' );
