#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use RPC::XML::ParserFactory;

my $p = RPC::XML::ParserFactory->new();
my $app = MyXMLRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "XMLRPC ping (POST)" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [ 'Content-Type' => 'text/xml' ],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
<methodName>ping</methodName>
<params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    my $value = $p->parse($response->decoded_content)->value->value;
    is_deeply(
        $value,
        'pong',
        "ping"
    ) or diag(explain($value));
};

subtest "XMLRPC ping (GET)" => sub {
    my $request = HTTP::Request->new(
        GET => '/endpoint',
        [ 'Content-Type' => 'text/xml' ],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
<methodName>ping</methodName>
<params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Check method POST for xmlrpc");
};

subtest "XMLRPC wrong content-type (404)" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [ 'Content-Type' => 'application/json', ],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>ping</methodName>
    <params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Check content-type xmlrpc")
        or diag(explain($response));
};

subtest "XMLRPC unknown rpc-method (404)" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        ['Content-Type' => 'text/xml'],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>system.doesnotexist</methodName>
    <params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, '404 Not Found', "Check known rpc-methods");
};

subtest "XMLRPC methodList(plugin => 'xmlrpc')" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        ['Content-Type' => 'text/xml'],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>methodList</methodName>
    <params>
      <param>
        <struct>
          <member>
            <name>plugin</name>
            <value><string>xmlrpc</string></value>
          </member>
        </struct>
      </param>
    </params>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, '200 OK', "OK response");

    my $methods = $p->parse($response->decoded_content)->value->value;
    is_deeply(
        $methods,
        {
            '/endpoint' => [qw/
                methodList
                ping
                version
            /]
        },
        "methodList(plugin => 'xmlrpc')"
    ) or diag(explain($methods));
};

abeltje_done_testing();

BEGIN {
    package MyXMLRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::XMLRPC;

    BEGIN { set(log => 'error') }
    xmlrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    1;
}
