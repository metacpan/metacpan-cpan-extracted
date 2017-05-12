#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More;

BEGIN {
    eval {
        require Catalyst::Plugin::Session::State::Cookie;
        Catalyst::Plugin::Session::State::Cookie->VERSION(0.03);
    } or plan skip_all => "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";
    
    eval { require Test::WWW::Mechanize::Catalyst }
        or plan skip_all => "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 46;
}

use Test::WWW::Mechanize::Catalyst "RewritingTestApp";

foreach my $use_cookies (1, 0) {
    my $m = Test::WWW::Mechanize::Catalyst->new( $use_cookies ? () : ( cookie_jar => undef ) );

    $m->get_ok( "http://localhost/first_request", "initial request" );

    $m->content_like( qr/counter: 1\b/, "counter at 1" );

    my $second = $m->find_link( text => "second");

    # the first request *always* gets rewritten links because we don't know if the UA supports cookies yet
    like( $second->URI, qr{/-/}, "uri was rewritten for first request" );

    $m->follow_link_ok( { text => "second" }, "go to second page" );

    $m->content_like( qr/counter: 2\b/, "counter at 2" );

    my $third = $m->find_link( text => "third" );

    if ( $use_cookies) {
        unlike( $third->URI, qr{/-/}, "uri has not been rewritten because a cookie was sent" );
    } else {
        like( $third->URI, qr{/-/}, "uri was rewritten" );
    }
    
    $m->follow_link_ok( { text => "third" }, "go to third page" );

    $m->content_like( qr/counter: 3\b/, "counter at 3" );

    no warnings 'redefine', 'once';
    local *Test::WWW::Mechanize::redirect_ok = sub { 0 };

    $m->get( "http://localhost/redirect", "got redirect" );
    my $resp = $m->response;
    is( $resp->code, 302, "got a 302 response" );

    unless ($use_cookies) {
        like( $resp->header("Location"), qr{/-/.+$},
              "Location header has session id with redirect" );
    }

    $m->get( "http://localhost/only_rewrite_redirect", "got redirect" );

    $resp = $m->response;
    is( $resp->code, 302, "got a 302 response" );

    unless ($use_cookies) {
        like( $resp->header("Location"), qr{/-/.+$},
              "Location header has session id with redirect and rewrite_redirect true" );
    }

    $m->get( "http://localhost/dont_rewrite_redirect", "got redirect" );

    $resp = $m->response;
    is( $resp->code, 302, "got a 302 response" );

    unlike( $resp->header("Location"), qr{/-/.+$},
            "Location header does not have session id with redirect and rewrite_redirect false" );

    unless ($use_cookies) {
        $m->get_ok( "http://localhost/only_rewrite_body", "get only_rewrite_body" );

        my $third = $m->find_link( text => "third" );
        like( $third->URI, qr{/-/},
              "body uri was rewritten" );

        $m->get_ok( "http://localhost/dont_rewrite_body", "get dont_rewrite_body" );

        $third = $m->find_link( text => "third" );
        unlike( $third->URI, qr{/-/},
                "body uri was not rewritten" );
    }
}

{
    my $m = Test::WWW::Mechanize::Catalyst->new( cookie_jar => undef );

    $m->get_ok("http://localhost/text_request?plain=0", "get text req as non plaintext");
    $m->content_like( qr/counter: 42\b/, "counter in body" );
    $m->content_like( qr{/-/}, "body rewritten" );

    $m->get_ok("http://localhost/text_request?plain=1", "get text req as plain text");
    $m->content_like( qr/counter: 42\b/, "counter in body" );
    $m->content_unlike( qr{/-/}, "body not rewritten because of wrong content type" );
}
