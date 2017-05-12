#! perl -w
use strict;
use Test::More;

use Dancer qw/:syntax !pass/;
use Dancer::Plugin::RPC::JSONRPC;
use Dancer::Plugin::RPC::XMLRPC;
use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::DispatchMethodList;

use Dancer::Test;
use RPC::XML::ParserFactory;
my $p = RPC::XML::ParserFactory->new();

{
    my $ep = {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'code.ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
                'system.listMethods' => dispatch_item(
                    code => sub {
                        my ($method, $args) = @_;
                        require Dancer::RPCPlugin::DispatchMethodList;
                        return Dancer::RPCPlugin::DispatchMethodList::list_methods(
                            $args->{protocol} // 'any'
                        );
                    },
                ),
            };
        },
        callback => sub { return callback_success() },
    };
    jsonrpc '/system' => $ep;
    xmlrpc  '/system' => $ep;

    route_exists([POST => '/system'], "/system registered");

    my $response = dancer_response(
        POST => '/system',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'system.listMethods',
                    id      => 42,
                }
            ),
        }
    );
    my $list = from_json($response->{content})->{result};
    is_deeply(
        $list,
        {
            'jsonrpc' => {
                '/system' => ['code.ping', 'system.listMethods']
            },
            'xmlrpc' => {
                '/system' => ['code.ping', 'system.listMethods']
            },
        },
        "/system => system.listMethods"
    );

    my $xml_response = dancer_response(
        POST => '/system',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => <<'            XML',
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
    <methodName>system.listMethods</methodName>
    <params><param>
        <struct>
            <member><name>protocol</name><value><string>xmlrpc</string></value></member>
        </struct>
    </param></params>
</methodCall>
            XML
        }
    );
    my $xml_result = $p->parse($xml_response->{content})->value->value;
    is_deeply(
        $xml_result,
        {
            '/system' => ['code.ping', 'system.listMethods']
        },
        "/system => system.listMethods(xmlrpc)"
    );
}

done_testing();
