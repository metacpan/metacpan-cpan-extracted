#! perl -w
use strict;
use lib 't/lib';

use Test::More;

use TestProject;
use Dancer::Test;

use JSON;

route_exists([GET => '/system/ping'],    "GET /system/ping exists");
route_exists([GET => '/system/version'], "GET /system/version exists");

{
    my $response = dancer_response(
        GET => '/system/ping',
    );

    my $ping = from_json('{"response": true}');
    if (JSON->VERSION >= 2.90) {
        my $t = 1;
        $ping->{response} = bless \$t, 'JSON::PP::Boolean';
    }
    is_deeply(
        from_json($response->{content}),
        $ping,
        "GET /system/ping"
    ) or diag(explain($response));
}

{
    my $response = dancer_response(
        GET => '/system/version',
    );

    is_deeply(
        from_json($response->{content}),
        {software_version => $TestProject::SystemCalls::VERSION},
        "GET /system/version"
    ) or diag(explain($response));
}

route_exists([ POST => '/db/person' ],      "POST /db/person");
route_exists([ GET => '/db/person/:id' ],   "GET /db/person/:id");
route_exists([ PATCH => '/db/person/:id' ], "PATCH /db/person/:id");
route_exists([ GET => '/db/persons' ],      "GET /db/persons");

{
    my $response = dancer_response(
        POST => '/db/person',
        {
            headers => [
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
    is_deeply(
        from_json($response2->{content}),
        my $p2 = {
            id => 2,
            name => 'Abe',
            job => 'Hacker',
        },
        "create_person()"
    ) or diag(explain($response2->{content}));

    $response = dancer_response(
        PATCH => "/db/person/1",
        {
            headers => [ 'Content-Type' => 'application/json' ],
            body    => to_json({job => 'Hacker'}),
        }
    );
    is($response->{status}, 200, "status 200: update_person") or diag(explain($response));
    is_deeply(
        from_json($response->{content}),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "update_person()"
    ) or diag(explain($response->{content}));

    $response = dancer_response(GET => '/db/person/1');
    is($response->{status}, 200, "status 200: update_person") or diag(explain($response));
    is_deeply(
        from_json($response->{content}),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "get_person()"
    ) or diag(explain($response->{content}));

    my $response3 = dancer_response(GET => '/db/persons');
    is($response3->{status}, 200, "status 200: update_person") or diag(explain($response3));
    is_deeply(
        from_json($response3->{content}),
        [ $p1, $p2 ],
        "get_all_persons()"
    ) or diag(explain($response3->{content}));

}

{ # test with non JSON body (no content-type)
    my $response = dancer_response(
        POST => '/db/person',
        {
            headers => [ Origin => 'http://localhost' ],
            body => to_json(
                {
                    name => 'abeltje',
                    job  => 'hacker',
                }
            ),
        }
    );
    is($response->{status}, 404, "status 404: create_person") or diag(explain($response));
}

{ # test non existent path
    my $response = dancer_response(
        DELETE => '/db/persons',
    );
    is($response->{status}, 404, "status 404: DELETE /db/persons") or diag(explain($response));
}

done_testing();
