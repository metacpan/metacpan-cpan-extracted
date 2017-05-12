use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';
use Catalyst::Test 'MyApp1';
use HTTP::Request::Common qw( GET PUT POST DELETE );

{
    request( GET '/foo', ( Accept => 'application/json' ) );

    is(
        $MyApp1::Controller::C1::REQ{get}, 1,
        'GET request for /foo went to the right sub'
    );

    request( GET '/foo', ( Accept => '*/*' ) );

    is(
        $MyApp1::Controller::C1::REQ{get_html}, 1,
        'GET request for /foo that looks like a browser went to the right sub'
    );

    request( POST '/foo' );

    is(
        $MyApp1::Controller::C1::REQ{post}, 1,
        'POST request for /foo went to the right sub'
    );

    request( PUT '/foo' );

    is(
        $MyApp1::Controller::C1::REQ{put}, 1,
        'PUT request for /foo went to the right sub'
    );

    request( DELETE '/foo' );

    is(
        $MyApp1::Controller::C1::REQ{delete}, 1,
        'DELETE request for /foo went to the right sub'
    );
}

{
    request( GET '/c1/bar', ( Accept => 'application/json' ) );

    is(
        $MyApp1::Controller::C1::REQ{get}, 2,
        'GET request for /c1/bar went to the right sub'
    );

    request( GET '/c1/bar', ( Accept => '*/*', ) );

    is(
        $MyApp1::Controller::C1::REQ{get_html}, 2,
        'GET request for /c1/bar that looks like a browser went to the right sub'
    );

    request( POST '/c1/bar' );

    is(
        $MyApp1::Controller::C1::REQ{post}, 2,
        'POST request for /c1/bar went to the right sub'
    );

    request( PUT '/c1/bar' );

    is(
        $MyApp1::Controller::C1::REQ{put}, 2,
        'PUT request for /c1/bar went to the right sub'
    );

    request( DELETE '/c1/bar' );

    is(
        $MyApp1::Controller::C1::REQ{delete}, 2,
        'DELETE request for /c1/bar went to the right sub'
    );
}

{
    request( GET '/chain1/42/chain2/84/baz/foo' );

    is(
        $MyApp1::Controller::C1::REQ{chain1}, 42,
        'chain1 chain point captured the first arg'
    );

    is(
        $MyApp1::Controller::C1::REQ{chain2}, 84,
        'chain2 chain point captured the second arg'
    );

    is(
        $MyApp1::Controller::C1::REQ{baz}, 'foo',
        'baz route captured the third arg'
    );
}

{
    request( GET '/user/99' );

    is(
        $MyApp1::Controller::C1::REQ{user}, 99,
        'get /user/99 calls _set_user chain point'
    );

    is(
        $MyApp1::Controller::C1::REQ{user_end}, 99,
        'get /user/99 calls get chained from _set_user'
    );
}

{
    request( GET '/thing/99' );

    is(
        $MyApp1::Controller::C1::REQ{thing}, 99,
        'get /thing/99 calls _set_thing chain point'
    );

    is(
        $MyApp1::Controller::C1::REQ{thing_end}, 99,
        'get /thing/99 calls get chained from _set_thing'
    );
}

{
    request( GET '/normal' );

    is(
        $MyApp1::Controller::C1::REQ{normal}, 1,
        'GET request for /normal went to the right sub'
    );

    request( POST '/normal' );

    is(
        $MyApp1::Controller::C1::REQ{normal}, 2,
        'POST request for /normal went to the right sub'
    );
}

{
    request( GET '/' );

    is(
        $MyApp1::Controller::Root::REQ{root}, 1,
        'GET request for / went to the right sub (routes work when namespace is empty string)'
    );

    request( GET '/foo.txt' );

    is(
        $MyApp1::Controller::Root::REQ{'foo.txt'}, 1,
        'GET request for /foo.txt went to the right sub (routes work when namespace is empty string)'
    );
}

done_testing();
