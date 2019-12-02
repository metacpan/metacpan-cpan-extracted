#! perl -w
use strict;
use lib 't/lib';

use Test::More;

BEGIN { $ENV{DANCER_APPDIR} = '.'; }
use TestProjectCORS;
use Dancer::Test;

use JSON;

route_exists([ POST => '/db/person' ],      "POST /db/person");
route_exists([ GET => '/db/person/:id' ],   "GET /db/person/:id");
route_exists([ PATCH => '/db/person/:id' ], "PATCH /db/person/:id");
route_exists([ GET => '/db/persons' ],      "GET /db/persons");

{
    my $access1 = dancer_response(
        OPTIONS => '/db/person',
        {
            headers => [
                'Origin'                         => 'http://localhost',
                'Access-Control-Request-Method'  => 'POST',
            ],
        }
    );
    is(
        $access1->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($access1));
    is(
        $access1->header('access-control-allow-methods'),
        'POST',
        "Got access-control-allow-methods"
    ) or diag(explain($access1));

    my $response = dancer_response(
        POST => '/db/person',
        {
            headers => [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            body => to_json(
                {
                    name => 'abeltje',
                    job  => 'hacker',
                }
            ),
        }
    );
    is($response->{status}, 200, "status 200: create_person") or diag(explain($response));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->{content}),
        my $p1 ={
            id => 1,
            name => 'abeltje',
            job => 'hacker',
        },
        "create_person()"
    ) or diag(explain($response->{content}));

    my $response2 = dancer_response(
        POST => '/db/person',
        {
            headers => [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            body => to_json(
                {
                    name => 'Abe',
                    job  => 'Hacker',
                }
            ),
        }
    );
    is($response2->{status}, 200, "status 200: create_person") or diag(explain($response2));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response2->{content}),
        my $p2 = {
            id => 2,
            name => 'Abe',
            job => 'Hacker',
        },
        "create_person()"
    ) or diag(explain($response2->{content}));

    # preflight the 3nd request
    my $access3 = dancer_response(
        OPTIONS => '/db/person/1',
        {
            headers => [
                'Origin'                         => 'http://localhost',
                'Access-Control-Request-Method'  => 'PATCH',
            ],
        }
    );
    is(
        $access3->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($access3));
    is(
        $access3->header('access-control-allow-methods'),
        'PATCH',
        "Got access-control-allow-methods"
    ) or diag(explain($access3));

    $response = dancer_response(
        PATCH => "/db/person/1",
        {
            headers => [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            body    => to_json({job => 'Hacker'}),
        }
    );
    is($response->{status}, 200, "status 200: update_person") or diag(explain($response));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->{content}),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "update_person()"
    ) or diag(explain($response->{content}));

    my $access4 = dancer_response(
        OPTIONS => '/db/person/1',
        {
            headers => [
                'Origin'                         => 'http://localhost',
            ],
        }
    );
    is(
        $access4->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($access4));
    is(
        $access4->header('access-control-allow-methods'),
        'GET',
        "Got access-control-allow-methods"
    ) or diag(explain($access3));

    $response = dancer_response(
        GET => '/db/person/1',
        { headers => [Origin => 'http://localhost'] }
    );
    is($response->{status}, 200, "status 200: update_person") or diag(explain($response));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->{content}),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "get_person()"
    ) or diag(explain($response->{content}));

    my $access5 = dancer_response(
        OPTIONS => '/db/persons',
        { headers => [ 'Origin' => 'http://localhost' ] }
    );
    is(
        $access5->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($access5));
    is(
        $access5->header('access-control-allow-methods'),
        'GET',
        "Got access-control-allow-methods"
    ) or diag(explain($access5));

    my $response3 = dancer_response(
        GET => '/db/persons',
        { headers => [ Origin => 'http://localhost' ] }
    );
    is($response3->{status}, 200, "status 200: update_person") or diag(explain($response3));
    is(
        $response3->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response3));
    is_deeply(
        from_json($response3->{content}),
        [ $p1, $p2 ],
        "get_all_persons()"
    ) or diag(explain($response3->{content}));


    my $no_access = dancer_response(
        OPTIONS => '/db/persons',
        {
            headers => [
                Origin => 'http://localhost',
                'Access-Control-Request-Method' => 'POST',
            ]
        }
    );
    is(
        $no_access->{content},
        '[CORS-preflight] failed for POST => /db/persons',
        "Cannot POST to /db/persons (preflight)"
    ) or diag(explain($no_access));

    $no_access = dancer_response(
        OPTIONS => '/system/version',
        {
            headers => [
                'Origin' => 'http://localhost',
                'Access-Control-Request-Method' => 'GET',
            ],
        }
    );
    is(
        $no_access->{content},
        "[CORS] http://localhost not allowed",
        "http://localhost not allowed for CORS"
    ) or diag(explain($no_access));
}

done_testing();
