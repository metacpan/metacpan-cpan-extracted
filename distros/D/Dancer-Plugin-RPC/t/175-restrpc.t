#! perl -I. -w
use t::Test::abeltje;

BEGIN { $ENV{DANCER_APPDIR} = 't' }
use TestProject;
use Dancer::Test;

use JSON;

route_exists([POST => '/rest/system/ping'], "system/ping exsits");

{
    my $response = dancer_response(
        POST => '/rest/system/version',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $version = from_json($response->content);
    is_deeply(
        $version,
        {software_version => '1.0'},
        "system.version"
    );
}

{
    my $response = dancer_response(
        POST => '/rest/system/four_o_four',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    is($response->status, 404, "Check endpoint");
}

{
    my $response = dancer_response(
        POST => '/rest/system/ping',
        {
            headers => [
                'Content-Type' => 'form',
            ],
        }
    );

    is($response->status, 404, "Check content-type restrpc");
}

{
    my $old_log = read_logs(); # clean up for this test
    my $response = dancer_response(
        POST => '/rest/api/uppercase',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                { argument => 'Alles grote letters' }
            ),
        }
    );

    is_deeply(
        from_json($response->{content}),
        {uppercase => 'ALLES GROTE LETTERS'},
        "/rest/api/uppercase"
    ) or diag(explain($response));

    my @expected_logs = (
        {
            level   => 'debug',
            message => qr{^\Q[handle_restrpc_request] Processing:}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handle_restrpc_call(uppercase)]}
        },
        {
            level   => 'debug',
            message => qr{^\Q[uppercase] {'argument' => 'Alles grote letters'}}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handled_restrpc_request(uppercase)]}
        },
        {
            level   => 'info',
            message => qr{^\Q[RPC::RESTRPC]\E request for uppercase took 0\.\d+s},
        },
        {
            level   => 'debug',
            message => qr{^\Q[restrpc_response] }
        },
    );

    my $read_logs = read_logs();
    for my $line (@$read_logs) {
        my $test = shift @expected_logs;
        is($line->{level}, $test->{level}, "  Level ");
        like($line->{message}, $test->{message}, "  Message ") or diag($line->{message});
    }
}

abeltje_done_testing();
