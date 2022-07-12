#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use RPC::XML::ParserFactory;

my $p = RPC::XML::ParserFactory->new();
my $app = MyXMLRPCAppCallbackFail->to_app();
my $tester = Plack::Test->create($app);

subtest "XMLRPC Callback::Fail" => sub {
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
    my $response_data = $p->parse($response->decoded_content)->value->value;
    is_deeply(
        $response_data,
        {
            'faultCode'   => 500,
            'faultString' => "Callback die()s\n",
        },
        "CallbackFail"
    ) or diag(explain($response_data));
};

abeltje_done_testing();

BEGIN {
    package MyXMLRPCAppCallbackFail;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::XMLRPC;
    use Dancer2::RPCPlugin::CallbackResultFactory;

    BEGIN { set(log => 'error') }
    xmlrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        callback  => sub {
            die "Callback die()s\n";
        },
    };
    1;
}
