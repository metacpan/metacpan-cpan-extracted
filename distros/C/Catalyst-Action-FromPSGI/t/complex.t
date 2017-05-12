#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Catalyst::Test 'Simplyst';
use HTTP::Request::Common;

is( get('/complex/from_plack/foo'), 'Hello local world', 'app under Local works');
is( get('/globule/foo'), 'Hello globule world', 'app under Global works');
is( get('/chain1/frew/middle/frue/end/foo'), 'Hello chain: frew, frue world', 'app under Chain works');

{
    my $request = POST(
        '/complex/post_content',
        'Content'      => {qw(foo bar baz quux)},
        'Content-Type' => 'application/x-www-form-urlencoded'
    );

    ok( my $response = request($request), 'response received' );
    ok( $response->is_success, 'Response successful 2xx' );
}

{
    my $request = POST(
        '/complex/post_content',
        'Content'      => 'foobar',
        'Content-Type' => 'text/plain'
    );

    ok( my $response = request($request), 'response received' );
    ok( $response->is_success, 'Response successful 2xx' );
}

{
    my $request = POST(
        '/complex/post_content2',
        'Content'      => {qw(foo bar)},
        'Content-Type' => 'application/x-www-form-urlencoded'
    );

    ok( my $response = request($request), 'response received' );
    ok( $response->is_success, 'Response successful 2xx' );
    is( $response->content, 'bar', 'data is correctly parsed out' );
}
done_testing();

