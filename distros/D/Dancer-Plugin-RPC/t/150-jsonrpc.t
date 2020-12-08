#! perl -I. -w
use t::Test::abeltje;

BEGIN { $ENV{DANCER_APPDIR} = 't' }
use TestProject;
use Dancer::Test;

use JSON;

route_exists([POST => '/jsonrpc/api'],    "/api exists");
route_exists([POST => '/jsonrpc/admin'],  "/jsonrpc/admin exists");

route_doesnt_exist([GET => '/'], "no GET /");

{
    my $old_log = read_logs(); # clean up for this test
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
                    params  => {argument => 'Alles grote letters'}
                }
            ),
        }
    );

    is_deeply(
        from_json($response->{content})->{result},
        {uppercase => 'ALLES GROTE LETTERS'},
        "system.version"
    ) or diag(explain($response));

    my @expected_logs = (
        {
            level   => 'debug',
            message => qr{^\Q[handle_jsonrpc_request] Processing:}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handle_jsonrpc_call(api.uppercase)]}
        },
        {
            level   => 'debug',
            message => qr{^\Q[uppercase] {'argument' => 'Alles grote letters'}}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handled_jsonrpc_request(api.uppercase)]}
        },
        {
            level   => 'info',
            message => qr{^\Q[RPC::JSONRPC]\E request for api.uppercase took 0\.\d+s},
        },
        {
            level   => 'debug',
            message => qr{^\Q[jsonrpc_response] }
        },
    );

    my $read_logs = read_logs();
    for my $line (@$read_logs) {
        my $test = shift @expected_logs;
        is($line->{level}, $test->{level}, "  Level ");
        like($line->{message}, $test->{message}, "  Message ") or diag($line->{message});
    }
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

    is($response->{status}, 404, "Not found (not jsonrpc-content-type)")
        or diag(explain($response));

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

    is($response->{status}, 200, "Transport OK");
    is_deeply(
        from_json($response->{content})->{error},
        {code => -32601, message => "Method 'api.lowercase' not found"},
        "Unknown jsonrpc-method"
    ) or diag(explain($response));
}

abeltje_done_testing();
