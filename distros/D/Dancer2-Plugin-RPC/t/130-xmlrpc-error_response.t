#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use Dancer2::RPCPlugin::ErrorResponse;
use RPC::XML;
use RPC::XML::ParserFactory;
my $p = RPC::XML::ParserFactory->new();

my $app = MyXMLRPCApp->to_app();
my $tester = Plack::Test->create($app);

{
    note("XMLRPC return ErrorResponse");
    our $CodeWrapped = sub {
        return error_response(error_code => 42, error_message => "It went wrong :(");
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint',
        [
            'Content-type' => 'text/xml',
            'Accept'       => 'text/xml',
        ],
        RPC::XML::request->new('ping')->as_string,
    );

    my $response = $tester->request($request);
    my $response_result = $p->parse($response->content)->value; 
    is_deeply(
        $response_result->value,
        {
            faultCode   => 42,
            faultString => 'It went wrong :(',
        },
        "::ErrorResponse was processed"
    ) or diag(explain($response_result));
}

{
    note("XMLRPC codewrapper returns an object");
    our $CodeWrapped = sub {
        return bless {dummy => 42}, 'AnyClass';
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint',
        [
            'Content-type' => 'text/xml',
            'Accept'       => 'text/xml',
        ],
        RPC::XML::request->new('ping')->as_string
    );

    my $response = $tester->request($request);
    my $response_result = $p->parse($response->content)->value;
    is_deeply(
        $response_result->value,
        { dummy => 42 },
        "flatten_data() was used"
    ) or diag(explain($response_result));
};

abeltje_done_testing();

BEGIN {
    package MyXMLRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::XMLRPC;

    BEGIN {
        set(log => 'error');
    }
    xmlrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        code_wrapper => sub { $::CodeWrapped->() },
    };

    1;
}
