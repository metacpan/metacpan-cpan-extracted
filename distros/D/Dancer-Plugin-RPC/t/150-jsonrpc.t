#! perl -I. -w
use t::Test::abeltje;

use TestProject;
use Dancer::Test;

use JSON;

route_exists([POST => '/jsonrpc/api'],    "/api exists");
route_exists([POST => '/jsonrpc/admin'],  "/jsonrpc/admin exists");

route_doesnt_exist([GET => '/'], "no GET /");

{
    my $response = dancer_response(
        POST => '/jsonrpc/api',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => encode_json(
                {
                    jsonrpc => '2.0',
                    method  => 'api.uppercase',
                    id      => 42,
                    params  => {argument => 'uppercase'}
                }
            ),
        }
    );

    note(explain($response));
    is_deeply(
        from_json($response->{content})->{result},
        {uppercase => 'UPPERCASE'},
        "system.version"
    );
}

{
    my $response = dancer_response(
        POST => '/jsonrpc/api',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => encode_json(
                {argument => 'uppercase'}
            ),
        }
    );

    is($response->{status}, 404, "Not found (not jsonrpc-body)")
        or diag(explain($response));
}

{
    my $response = dancer_response(
        POST => '/jsonrpc/api',
        {
            headers => [
                'Content-Type' => 'application/xmlrpc',
            ],
            body => encode_json(
                {
                    jsonrpc => '2.0',
                    method  => 'api.uppercase',
                    id      => 42,
                    params  => {argument => 'uppercase'}
                }
            ),
        }
    );

    note(explain($response));
    is($response->{status}, 404, "Not found (not jsonrpc-content-type)");
}

{
    my $response = dancer_response(
        POST => '/jsonrpc/api',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => encode_json(
                {
                    jsonrpc => '2.0',
                    method  => 'api.lowercase',
                    id      => 42,
                    params  => {argument => 'uppercase'}
                }
            ),
        }
    );

    note(explain($response));
    is($response->{status}, 200, "Transport OK");
    is_deeply(
        from_json($response->{content})->{error},
        {code => -32601, message => "Method 'api.lowercase' not found"},
        "Unknown jsonrpc-method"
    );
}

done_testing();
