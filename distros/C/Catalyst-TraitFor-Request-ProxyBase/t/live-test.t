#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Request::Common;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use TestApp;

# a live test against TestApp, the test application
use Catalyst::Test 'TestApp';

sub req_with_base {
    my $base = shift;

    my $request_host = shift || 'http://localhost/';

    my ($res, $c) = ctx_request(GET($request_host, 'X-Request-Base' => $base ));
    return $c;
}


is(req_with_base('http://localhost/')->res->body, 'http://localhost/');
is(req_with_base('https://localhost/')->res->body, 'https://localhost/');
ok req_with_base('https://localhost/')->req->secure;

is(req_with_base('https://example.com:445/')->res->body, 'https://example.com:445/');
is(req_with_base('http://example.com:443/')->res->body, 'http://example.com:443/');
is(req_with_base('https://example.com:445/some/path')->res->body, 'https://example.com:445/some/path/');
is(req_with_base('https://example.com:445/some/path/')->res->body, 'https://example.com:445/some/path/');
is(req_with_base('https://example.com:445/some/path/')->req->uri->scheme, 'https');
is(req_with_base('https://example.com:445/some/path/')->req->uri->path, '/some/path/');
is(req_with_base('https://example.com:445/some/path/', 'http://localhost/chickens')->req->uri->path, '/some/path/chickens');

ok req_with_base('https://example.com:80/')->req->secure;
ok !req_with_base('http://example.com:443/')->req->secure;

is(req_with_base('/preview','http://example.com:80')->res->body, 'http://example.com/preview/');
is(req_with_base('/preview','https://example.com:80')->res->body, 'https://example.com/preview/');
is(req_with_base('/preview','https://example.com:443')->res->body, 'https://example.com/preview/');


{
    my $c = req_with_base('http://example.com/preview/');

    is( $c->req->base, "http://example.com/preview/" );
    is( $c->uri_for('/more'), "http://example.com/preview/more" );
    is( $c->uri_for('more'), "http://example.com/preview/more" );
    is( $c->uri_for('/more//double'), "http://example.com/preview/more//double" );
}

done_testing;

