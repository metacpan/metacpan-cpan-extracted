#! perl -I. -w
use t::Test::abeltje;

BEGIN { $ENV{DANCER_APPDIR} = 't' }
use TestProject;
use Dancer::Test;

route_exists([POST => '/system'], "/system exsits");
route_exists([POST => '/api'],    "/api exists");
route_exists([POST => '/config/system'],  "/config/system exists");
route_exists([POST => '/config/api'],     "/config/api exists");

route_doesnt_exist([GET => '/system'], "No get for /system");
route_doesnt_exist([GET => '/'], "no GET /");
{
    my $response = dancer_response(
        POST => '/system',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>system.version</methodName>
    <params/>
</methodCall>
        EOXML
        }
    );

    use RPC::XML::ParserFactory;
    my $p = RPC::XML::ParserFactory->new();
    is_deeply(
        $p->parse($response->{content})->value->value,
        {software_version => '1.0'},
        "system.version"
    );
}

{
    my $response = dancer_response(
        GET => '/system',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>system.version</methodName>
    <params/>
</methodCall>
        EOXML
        }
    );
    is($response->status, 404, "Check method POST for xmlrpc");
}

{
    my $response = dancer_response(
        POST => '/system',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>system.version</methodName>
    <params/>
</methodCall>
        EOXML
        }
    );
    is($response->status, 404, "Check content-type xmlrpc");
}

{
    my $response = dancer_response(
        POST => '/system',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>system.doesnotexist</methodName>
    <params/>
</methodCall>
        EOXML
        }
    );
    is($response->status, 404, "Check content-type xmlrpc");
}

{
    my $old_log = read_logs(); # clean up for this test
    my $response = dancer_response(
        POST => '/api',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>api.uppercase</methodName>
    <params>
      <param>
        <struct>
          <member>
            <name>argument</name>
            <value><string>Alles grote letters</string></value>
          </member>
        </struct>
      </param>
    </params>
</methodCall>
        EOXML
        }
    );
    is($response->status, 200, "OK response");

    my $p = RPC::XML::ParserFactory->new();
    is_deeply(
        $p->parse($response->{content})->value->value,
        {uppercase => 'ALLES GROTE LETTERS'},
        "system.version"
    );

    my @expected_logs = (
        {
            level   => 'debug',
            message => qr{^\Q[handle_xmlrpc_request] Processing:}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handle_xmlrpc_call(api.uppercase)]}
        },
        {
            level   => 'debug',
            message => qr{^\Q[uppercase] {'argument' => 'Alles grote letters'}}
        },
        {
            level   => 'debug',
            message => qr{^\Q[handled_xmlrpc_request(api.uppercase)]}
        },
        {
            level   => 'info',
            message => qr{^\Q[RPC::XMLRPC]\E request for api.uppercase took 0\.\d+s},
        },
        {
            level   => 'debug',
            message => qr{^\Q[xmlrpc_response] }
        },
    );

    my $read_logs = read_logs();
    for my $line (@$read_logs) {
        my $test = shift @expected_logs;
        is($line->{level}, $test->{level}, "  Level ");
        like($line->{message}, $test->{message}, "  Message ");
    }
}

abeltje_done_testing();
