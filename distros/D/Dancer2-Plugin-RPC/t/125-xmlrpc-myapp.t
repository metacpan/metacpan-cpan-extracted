#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use RPC::XML::ParserFactory;

my $p = RPC::XML::ParserFactory->new();
my $app = MyAllRPCApp->to_app();
my $tester = Plack::Test->create($app);


subtest "XMLRPC ping" => sub {
    local $Data::Dumper::Purity = 0;
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
    is($response->status_line, '200 OK', "OK response");

    is_deeply(
        $p->parse($response->decoded_content)->value->value,
        'pong',
        "ping"
    );
};

subtest "XMLRPC version" => sub {
    local $Data::Dumper::Purity = 0;
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [ 'Content-Type' => 'text/xml' ],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>version</methodName>
    <params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, '200 OK', "OK response");

    is_deeply(
        $p->parse($response->decoded_content)->value->value,
        {software => $MyAppCode::VERSION},
        "version"
    );
};

subtest "XMLRPC methodList()" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        ['Content-Type' => 'text/xml'],
        <<'        EOXML',
<?xml version="1.0"?>
<methodCall>
    <methodName>methodList</methodName>
    <params/>
</methodCall>
        EOXML
    );
    my $response = $tester->request($request);
    is($response->status_line, '200 OK', "OK response");

    my $methods = $p->parse($response->decoded_content)->value->value;
    is_deeply(
        $methods,
        {
            'jsonrpc' => {'/endpoint' => ['method.list', 'ping', 'version']},
            'restrpc' => {'/endpoint' => ['method_list', 'ping', 'version']},
            'xmlrpc'  => {'/endpoint' => ['methodList',  'ping', 'version']}
        },
        "methodList(plugin => 'xmlrpc')"
    ) or diag(explain($methods // $response));
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
    package MyAllRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::XMLRPC;
    use Dancer2::Plugin::RPC::RESTRPC;
    use Dancer2::Plugin::RPC::JSONRPC;

    BEGIN { set(logger => 'Null') }
    xmlrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    restrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    jsonrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    1;
}
