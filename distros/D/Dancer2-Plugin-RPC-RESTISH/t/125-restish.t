#! perl -I. -w
use t::Test::abeltje;

use TestProject;
use Plack::Test;

use HTTP::Request;
use JSON;

my $app = TestProject->to_app();
my $tester = Plack::Test->create($app);

{
    my $request = HTTP::Request->new(
        GET => '/system/ping',
    );
    my $response = $tester->request($request);

    my $ping = from_json('{"response": true}');
    is_deeply(
        from_json($response->content),
        $ping,
        "GET /system/ping"
    ) or diag(explain($response));
}

{
    my $request = HTTP::Request->new(
        GET => '/system/version',
    );
    my $response = $tester->request($request);

    is_deeply(
        from_json($response->content),
        {software_version => $TestProject::SystemCalls::VERSION},
        "GET /system/version"
    ) or diag(explain($response));
}

{
    my $request = HTTP::Request->new(
        POST => '/db/person',
        [
            'Content-Type' => 'application/json'
        ],
        to_json(
            {
                name => 'abeltje',
                job  => 'hacker',
            }
        ),
    );
    my $response = $tester->request($request);
    is($response->code, 200, "status 200: create_person") or diag(explain($response));
    is_deeply(
        from_json($response->content),
        my $p1 ={
            id => 1,
            name => 'abeltje',
            job => 'hacker',
        },
        "create_person()"
    ) or diag(explain($response->{content}));

    my $request2 = HTTP::Request->new(
        POST => '/db/person',
        [
            'Content-Type' => 'application/json'
        ],
        to_json(
            {
                name => 'Abe',
                job  => 'Hacker',
            }
        ),
    );
    my $response2 = $tester->request($request2);
    is($response2->code, 200, "status 200: create_person") or diag(explain($response2));
    is_deeply(
        from_json($response2->content),
        my $p2 = {
            id => 2,
            name => 'Abe',
            job => 'Hacker',
        },
        "create_person()"
    ) or diag(explain($response2->{content}));

    $response = $tester->request(
        HTTP::Request->new(
            PATCH => "/db/person/1",
            [ 'Content-Type' => 'application/json' ],
            to_json({job => 'Hacker'}),
        )
    );
    is($response->code, 200, "status 200: update_person") or diag(explain($response));
    is_deeply(
        from_json($response->content),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "update_person()"
    ) or diag(explain($response->content));

    $response = $tester->request(HTTP::Request->new(GET => '/db/person/1'));
    is($response->code, 200, "status 200: update_person") or diag(explain($response));
    is_deeply(
        from_json($response->content),
        $p1 = {
            id => 1,
            name => 'abeltje',
            job => 'Hacker',
        },
        "get_person()"
    ) or diag(explain($response->content));

    my $response3 = $tester->request(HTTP::Request->new(GET => '/db/persons'));
    is($response3->code, 200, "status 200: update_person") or diag(explain($response3));
    is_deeply(
        from_json($response3->content),
        [ $p1, $p2 ],
        "get_all_persons()"
    ) or diag(explain($response3->content));

}

{ # test with non JSON body (no content-type)
    my $response = $tester->request(
        HTTP::Request->new(
            POST => '/db/person',
            [ Origin => 'http://localhost' ],
            to_json(
                {
                    name => 'abeltje',
                    job  => 'hacker',
                }
            ),
        )
    );
    is($response->code, 404, "status 404: create_person") or diag(explain($response));
}

{ # test non existent path
    my $response = $tester->request(
        HTTP::Request->new(DELETE => '/db/persons')
    );
    is($response->code, 404, "status 404: DELETE /db/persons") or diag(explain($response));
}

abeltje_done_testing();
