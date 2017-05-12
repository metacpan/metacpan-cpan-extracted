#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::MockObject::Extends;
use URI;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session::State::URI" ) }

{
    package HashObj;
    use base qw/Class::Accessor/;
    __PACKAGE__->mk_accessors(qw/body path base content_type status/);
}

my $req = Test::MockObject::Extends->new( HashObj->new );
$req->base( URI->new( "http://myapp/" ) );

my $res = Test::MockObject::Extends->new( HashObj->new );

{
    package MockCtx;
    use base qw/
        Catalyst::Plugin::Session
        Catalyst::Plugin::Session::State::URI
    /;
}

my $cxt = Test::MockObject::Extends->new("MockCtx");

$cxt->set_always( config => { 'Plugin::Session' => { param => 'sid' } } );
$cxt->set_always( request  => $req );
$cxt->set_always( response => $res );
$cxt->set_false("debug");

my $sessionid;
$cxt->mock( sessionid => sub { shift; $sessionid = shift if @_; $sessionid } );
$cxt->mock( _sessionid_from_uri => sub { shift; $sessionid = shift if @_; $sessionid } );
$cxt->mock( _sessionid_to_rewrite => sub { shift; $sessionid = shift if @_; $sessionid } );

$sessionid = 'qux';
my $session_string = $cxt->config->{ 'Plugin::Session' }{ param } . '=' . $sessionid;

my $external_uri    = "http://www.woobling.org/";
my $internal_uri    = $req->base . "action01";
my $relative_uri    = "action02";
my $rel_with_slash  = "/action03";
my $rel_with_dot    = "./action04";
my $int_with_id     = $internal_uri . '?' . $session_string;
my $int_with_ext    = $internal_uri . '/logo.png';

$cxt->setup_session;

my %rewritten = (
    'http://myapp/'         => 'http://myapp/?' . $session_string,
	'http://myapp/?foo=bar' => 'http://myapp/?foo=bar&' . $session_string,
);

can_ok( $m, "uri_with_sessionid" );

foreach my $uri ( keys %rewritten ) {
    is( $cxt->uri_with_sessionid($uri), $rewritten{ $uri }, 'URI is rewritten as expected');
}

can_ok( $m, "session_should_rewrite_uri" );

ok(
    !$cxt->session_should_rewrite_uri( $external_uri ),
    "external URIs should not be rewritten"
);

ok(
    $cxt->session_should_rewrite_uri( $internal_uri ),
    "internal URIs should be rewritten"
);

foreach my $uri ( $relative_uri, $rel_with_slash, $rel_with_dot ) {
    ok(
        $cxt->session_should_rewrite_uri( $uri ),
        "relative URIs should be rewritten"
    );
}

ok(
    !$cxt->session_should_rewrite_uri( $int_with_id),
    "already rewritten internal URIs should not be rewritten again"
);

ok(
    !$cxt->session_should_rewrite_uri( $int_with_ext ),
    "binary media type should not be rewritten"
);

can_ok( $m, "prepare_path" );

can_ok( $m, "finalize" );

$res->body("foo");
$cxt->finalize;
is( $res->body, "foo", "body unchanged with no URLs" );

$res->body( my $body_ext_url = qq{foo <a href="$external_uri"></a> blah} );
$cxt->finalize;
is( $res->body, $body_ext_url, "external URL stays untouched" );

$res->content_type("text/html");

foreach my $uri ( $internal_uri, $relative_uri, $rel_with_slash, $rel_with_dot ) {

    $res->body( my $body_internal = qq{foo <a href="$uri"></a> bar} );
    $cxt->finalize;

    like( $res->body, qr#^foo <a href="$uri.*"></a> bar$#, "body was rewritten" );

    my @uris = ( $res->body =~ /href="(.*?)"/g );

    is( @uris, 1, "one uri was changed" );
    is(
        "$uris[0]",
        $cxt->uri_with_sessionid($uri),
        "rewritten to output of uri_with_sessionid"
    );
}
