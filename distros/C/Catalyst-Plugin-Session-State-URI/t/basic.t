#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 53;
use Test::MockObject::Extends;
use URI;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session::State::URI" ) }

{

    package HashObj;
    use base qw/Class::Accessor/;

    __PACKAGE__->mk_accessors(qw/body path base content_type location status/);
}

my $req = Test::MockObject::Extends->new( HashObj->new );
$req->base( URI->new( "http://server/app/" ));

my $res = Test::MockObject::Extends->new( HashObj->new );

my $external_uri         = "http://www.woobling.org/";
my $internal_uri         = $req->base . "somereq";
my $relative_uri         = "moose";
my $rel_with_slash       = "/app/foo";
my $rel_with_slash_ext   = "/fajkhat";
my $rel_with_dot_dot     = "../ljaht";
my $internal_uri_with_id = "${internal_uri}/-/foo";
my $uri_to_plaintext     = $req->base . "foo.txt";
my $uri_to_picture       = $req->base . "foo.png";

{
    package MockCtx;
    use base qw/
        Catalyst::Plugin::Session
        Catalyst::Plugin::Session::State::URI
    /;
}

my $cxt = Test::MockObject::Extends->new("MockCtx");

$cxt->set_always( config => {} );
$cxt->set_always( request  => $req );
$cxt->set_always( response => $res );
$cxt->set_false("debug");
my $sessionid;
$cxt->mock( sessionid => sub { shift; $sessionid = shift if @_; $sessionid } );
$cxt->mock( _sessionid_from_uri => sub { shift; $sessionid = shift if @_; $sessionid } );
$cxt->mock( _sessionid_to_rewrite => sub { shift; $sessionid = shift if @_; $sessionid } );

$cxt->setup_session;

can_ok( $m, "session_should_rewrite" );
ok( $cxt->session_should_rewrite, "sessions should rewrite by default" );

foreach my $uri (qw{ any http://string/in http://the/world }) {
    $sessionid = "foo";
    can_ok( $m, "uri_with_sessionid" );
    is( $cxt->uri_with_sessionid($uri), "${uri}/-/foo" );
    $sessionid = undef;
}

{
    $sessionid = 'bar';
    is( $cxt->uri_with_sessionid( q{/} ), "/-/bar" );
    is( $cxt->uri_with_sessionid( q{/trailing/slash/} ), "/trailing/slash/-/bar" );
    $sessionid = undef;
}

can_ok( $m, "session_should_rewrite_uri" );

ok(
    $cxt->session_should_rewrite_uri( $internal_uri ),
    "internal URIs should be rewritten"
);

ok(
    $cxt->session_should_rewrite_uri( $internal_uri ),
    "relative URIs should be rewritten"
);

ok(
    !$cxt->session_should_rewrite_uri( $internal_uri_with_id),
    "already rewritten internal URIs should not be rewritten again"
);

ok(
    $cxt->session_should_rewrite_uri( $uri_to_plaintext ),
    "rewrite URI to plain text file"
);

ok(
    !$cxt->session_should_rewrite_uri( $uri_to_picture ),
    "rewrite URI to but not to a png"
);

foreach my $uri ( $external_uri, $rel_with_slash_ext, $rel_with_dot_dot ) {
    ok(
        !$cxt->session_should_rewrite_uri( $uri ),
        "external URIs should not be rewritten"
    );
}

can_ok( $m, "prepare_path" );

$cxt->clear;
$req->path("somereq");

$cxt->prepare_path;
ok( !$cxt->called("sessionid"),
    "didn't try setting session ID when there was nothing to set it by" );

is( $req->path, "somereq", "req path unchanged" );

$req->path("some_req/-/the session id");
ok( !$cxt->get_session_id, "no session ID yet" );
$cxt->prepare_path;
is( $cxt->get_session_id, "the session id", "session ID was restored from URI" );
is( $req->path,      "some_req",       "request path was rewritten" );

$sessionid = undef;
$req->path("-/the session id");    # sri's bug
ok( !$cxt->get_session_id, "no session ID yet" );
$cxt->prepare_path;
is(
    $cxt->get_session_id,
    "the session id",
    "session ID was restored from URI with empty path"
);
is( $req->path, "", "request path was rewritten" );

can_ok( $m, "finalize" );

$res->body("foo");
$cxt->finalize;
is( $res->body, "foo", "body unchanged with no URLs" );

foreach my $uri ( $external_uri, $rel_with_slash_ext, $rel_with_dot_dot ) {
    $res->body( my $body_ext_url = qq{foo <a href="$uri"></a> blah} );
    $cxt->finalize;
    is( $res->body, $body_ext_url, "external URL stays untouched" );
}

$res->content_type("text/html");

foreach my $uri ( $internal_uri, $relative_uri, $rel_with_slash ) {

    $res->body( my $body_internal = qq{foo <a href="$uri"></a> bar} );
    $cxt->finalize;

    like( $res->body, qr#^foo <a href="$uri.+"></a> bar$#, "body was rewritten" );

    my @uris = ( $res->body =~ /href="(.*?)"/g );

    is( @uris, 1, "one uri was changed" );
    is(
        "$uris[0]",
        $cxt->uri_with_sessionid($uri),
        "rewritten to output of uri_with_sessionid"
    );
}

$res->content_type("text/plain");

foreach my $uri ( $internal_uri ) {

    $res->body( my $body_internal = qq{foo <$uri> bar} );
    $cxt->finalize;

    like( $res->body, qr#^foo <$uri.+> bar$#, "body was rewritten" );

    my @uris = ( $res->body =~ /<(.*?)>/g );

    is( @uris, 1, "one uri was changed" );
    is(
        "$uris[0]",
        $cxt->uri_with_sessionid($uri),
        "rewritten to output of uri_with_sessionid"
    );
}

$res->body("");
$res->status(302);

foreach my $uri ( $internal_uri, $relative_uri, $rel_with_slash ) {
    $res->location( $uri );
    $cxt->finalize;

    like( $res->location, qr/^$uri.+$/, "location header was rewritten" );

    is(
        $res->location,
        $cxt->uri_with_sessionid($uri),
        "rewritten to output of uri_with_sessionid"
    );
}

$cxt->set_false("session_should_rewrite");

$res->body(my $body_internal = qq{foo <a href="$internal_uri"></a> moose});
$cxt->finalize;
is( $res->body, $body_internal,
    "no rewriting when 'session_should_rewrite' returns a false value" );

