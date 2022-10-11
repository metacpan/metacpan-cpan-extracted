#! perl -I. -w
use t::Test::abeltje;


BEGIN { $ENV{DANCER_APPDIR} = '.'; }
use TestProjectCORS;
use Plack::Test;

use HTTP::Request;
use JSON;

my $app = TestProjectCORS->to_app();
my $tester = Plack::Test->create($app);

{
    my $access1 = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/db/person',
            [
                'Origin'                         => 'http://localhost',
                'Access-Control-Request-Method'  => 'POST',
            ],
        )
    );
    is(
        $access1->header('Access-Control-Allow-Origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($access1));

    is(
        $access1->header('Access-Control-Allow-Methods'),
        'POST',
        "Got access-control-allow-methods"
    ) or diag(explain($access1));

    my $response = $tester->request(
        HTTP::Request->new(
            POST => '/db/person',
            [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            to_json(
                {
                    name => 'abeltje',
                    job  => 'hacker',
                }
            ),
        )
    );
    is($response->code, 200, "status 200: create_person") or diag(explain($response));
    is(
        $response->header('Access-Control-Allow-Origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->content),
        my $p1 ={
            id => 1,
            name => 'abeltje',
            job => 'hacker',
        },
        "create_person()"
    ) or diag(explain($response->content));

    my $response2 = $tester->request(
        HTTP::Request->new(
            POST => '/db/person',
            [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            to_json(
                {
                    name => 'Abe',
                    job  => 'Hacker',
                }
            ),
        )
    );
    is($response2->code, 200, "status 200: create_person") or diag(explain($response2));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response2->content),
        my $p2 = {
            id => 2,
            name => 'Abe',
            job => 'Hacker',
        },
        "create_person()"
    ) or diag(explain($response2->content));

    # preflight the 3nd request
    my $access3 = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/db/person/1',
            [
                'Origin'                         => 'http://localhost',
                'Access-Control-Request-Method'  => 'PATCH',
            ],
        )
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

    $response = $tester->request(
        HTTP::Request->new(
            PATCH => "/db/person/1",
            [
                'Origin'       => 'http://localhost',
                'Content-Type' => 'application/json'
            ],
            to_json({job => 'Hacker'}),
        )
    );
    is($response->code, 200, "status 200: update_person") or diag(explain($response));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->content),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "update_person()"
    ) or diag(explain($response->content));

    my $access4 = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/db/person/1',
            [
                'Origin'                         => 'http://localhost',
            ],
        )
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

    $response = $tester->request(
        HTTP::Request->new(
            GET => '/db/person/1',
            [Origin => 'http://localhost']
        )
    );
    is($response->code, 200, "status 200: update_person") or diag(explain($response));
    is(
        $response->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response));
    is_deeply(
        from_json($response->content),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "get_person()"
    ) or diag(explain($response->content));

    my $access5 = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/db/persons',
            [ 'Origin' => 'http://localhost' ]
        )
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

    my $response3 = $tester->request(
        HTTP::Request->new(
            GET => '/db/persons',
            [ Origin => 'http://localhost' ]
        )
    );
    is($response3->code, 200, "status 200: update_person") or diag(explain($response3));
    is(
        $response3->header('access-control-allow-origin'),
        '*',
        "Got access-control-allow-origin"
    ) or diag(explain($response3));
    is_deeply(
        from_json($response3->content),
        [ $p1, $p2 ],
        "get_all_persons()"
    ) or diag(explain($response3->content));


    my $no_access = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/db/persons',
            [
                Origin => 'http://localhost',
                'Access-Control-Request-Method' => 'POST',
            ]
        )
    );
    is(
        $no_access->content,
        '[CORS-preflight] failed for POST => /db/persons',
        "Cannot POST to /db/persons (preflight)"
    ) or diag(explain($no_access));

    $no_access = $tester->request(
        HTTP::Request->new(
            OPTIONS => '/system/version',
            [
                'Origin' => 'http://localhost',
                'Access-Control-Request-Method' => 'GET',
            ],
        )
    );
    is(
        $no_access->content,
        "[CORS] http://localhost not allowed",
        "http://localhost not allowed for CORS"
    ) or diag(explain($no_access));
}

abeltje_done_testing();
