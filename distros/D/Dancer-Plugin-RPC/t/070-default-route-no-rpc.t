#! perl -I. -w
use t::Test::abeltje;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'test';
    $ENV{DANCER_APPDIR}      = '.';
}

use Dancer qw/:syntax !pass !warning/;
use Dancer::Test;

use MyTest::API;
use RPC::XML::ParserFactory;
use Dancer::RPCPlugin::DefaultRoute;
use Dancer::Plugin::RPC::JSONRPC;
use Dancer::Plugin::RPC::XMLRPC;
use Dancer::Plugin::RPC::RESTRPC;

use MyTest::API;
use MyTest::Client;

my $client = MyTest::Client->new(ping_value => 'pong');
my $dispatch = {
    'MyTest::API' => MyTest::API->new(test_client => $client),
};
my $config = {
    config       => 'config',
    code_wrapper => sub {
        my ($code, $package, $method) = splice(@_, 0, 3);
        my $instance = $dispatch->{$package};
        $instance->$code(@_);
    },
};

set(
    plugins => {
        'RPC::JSONRPC' => {
            '/jsonrpc' => {
                'MyTest::API' => {ping => 'rpc_ping'},
            },
        },
        'RPC::XMLRPC' => {
            '/xmlrpc' => {
                'MyTest::API' => {ping => 'rpc_ping'},
            },
        },
        'RPC::RESTRPC' => {
            '/restrpc' => {
                'MyTest::API' => {ping => 'rpc_ping'},
            },
        },
    }
);

for my $path (keys %{ config->{plugins}{'RPC::JSONRPC'} }) {
    jsonrpc $path => $config;
}
for my $path (keys %{ config->{plugins}{'RPC::XMLRPC'} }) {
    xmlrpc $path => $config;
}
for my $path (keys %{ config->{plugins}{'RPC::RESTRPC'} }) {
    restrpc $path => $config;
}

note("Send request to the *working* app without catch-all");
{
    my $response = dancer_response(
        POST => '/jsonrpc',
        {
            headers => [
                content_type => 'application/json',
            ],
            body => as_jsonrpc('ping'),
        }
    );
    response_contains_ok(
        $response,
        200,
        'application/json',
        {result => 'pong'},
        "ok(jsonrpc: ping)"
    );

    $response = dancer_response(
        POST => '/xmlrpc',
        {
            headers => [
                content_type => 'text/xml',
            ],
            body => as_xmlrpc('ping'),
        }
    );
    response_contains_ok(
        $response,
        200,
        'text/xml',
        {result => 'pong'},
        "ok(xmlrpc: ping)"
    );

    $response = dancer_response(
        POST => '/restrpc/ping',
        {
            headers => [
                content_type => 'application/json',
            ],
        }
    );
    response_contains_ok(
        $response,
        200,
        'application/json',
        {result => 'pong'},
        "ok(restrpc: ping)"
    );
}

note("Send *rubbish* to the working app **without** catch-all");
{
    my $response = dancer_response(
        POST => '/jsonrpc',
        {
            headers => [
                content_type => 'application/rubbish',
            ],
            body => as_jsonrpc('ping'),
        }
    );
    is($response->status, 404, "URI not found for content-type(jsonrpc)");
    is($response->content_type, 'text/html', "Content-Type set to html");

    $response = dancer_response(
        POST => '/xmlrpc',
        {
            headers => [
                content_type => 'application/rubbish',
            ],
            body => as_xmlrpc('ping'),
        }
    );
    response_contains_ok($response, 404, 'text/html', qr/Unable to process your query/);

    $response = dancer_response(
        POST => '/restrpc/ping',
        {
            headers => [
                content_type => 'application/rubbish',
            ],
        }
    );
    response_contains_ok($response, 404, 'text/html', qr/Unable to process your query/);
}

ok(setup_default_route(),"setting the catchall route");
note("Send *rubbish* to the working app **with** catch-all");
{

    my $response = dancer_response(
        POST => '/jsonrpc',
        {
            headers => [
                content_type => 'application/rubbish',
            ],
            body => as_jsonrpc('ping'),
        }
    );
    response_contains_ok(
        $response,
        404, 'text/plain',
        "Error! '/jsonrpc' was not found for 'application/rubbish'",
    );

    $response = dancer_response(
        POST => '/rubbish',
        {
            headers => [
                content_type => 'application/json',
                accept       => 'application/json',
            ],
            body => as_jsonrpc('ping'),
        }
    );
    response_contains_ok(
        $response,
        200, 'application/json',
        {
            code    => -32601,
            message => "Method 'ping' not found",
        }
    );

    $response = dancer_response(
        POST => '/rubbish',
        {
            headers => [
                content_type => 'text/xml',
            ],
            body => as_xmlrpc('ping'),
        }
    );
    response_contains_ok(
        $response,
        200, 'text/xml',
        {
            faultCode   => -32601,
            faultString => "Method 'ping' not found",
        }
    );

    $response = dancer_response(
        POST => '/rubbish/ping',
        {
            headers => [
                content_type => 'application/json',
                accept       => 'application/json',
            ],
            body => '',    #to_json(undef, {allow_nonref => 1}),
        }
    );
    response_contains_ok(
        $response,
        200,
        'application/json',
        {
            error => {
                code    => -32601,
                message => "Method 'ping' not found",
            }
        }
    );
}


done_testing();

sub as_jsonrpc {
    my ($method, $params) = @_;

    return to_json(
        {
            jsonrpc => '2.0',
            id      => "ID-$0-$$",
            method  => $method,
            (defined($params) ? (params => $params) : ())
        }
    );
}

sub as_xmlrpc {
    my ($method, $params) = @_;

    return RPC::XML::request->new($method => $params)->as_string();
}

sub response_contains_ok {
    my ($response, $status, $content_type, $content, $message) = @_;
    $message ||= 'response_contains_ok';

    my $parser = RPC::XML::ParserFactory->new();

    my $ok = 1;
    $ok &&= is(
        $response->status,
        $status,
        "$message: status ($status)"
    );
    $ok &&= is(
        $response->content_type,
        $content_type,
        "$message: content-type ($content_type)"
    );

    my $data;
    if ($response->content_type =~ m{(application|text)/xml}) {
        $data = $parser->parse($response->content)->value->value;
        $ok &&= is_deeply(
            $data,
            $content,
            "$message: content (xmlrpc)"
        );
    }
    elsif ($response->content_type eq 'application/json') {
        $data = from_json($response->content, {allow_nonref => 1});
        if (    defined($data) and ref($data) eq 'HASH'
            and exists($data->{jsonrpc}) and $data->{jsonrpc} eq '2.0')
        {
            if (exists($data->{error})) {
                $ok &&= is_deeply(
                    $data->{error},
                    $content,
                    "$message: content (jsonrpc-error)"
                );
            }
            else {
                $ok &&= is_deeply(
                    $data->{result},
                    $content,
                    "$message: content (jsonrpc-result)"
                );
            }
        }
    }
    else {
        $data = $response->content;
        if (ref($content) eq 'Regexp') {
            $ok &&= like($data, $content, "$message: content ($content)");
        }
        else {
            $ok &&= is_deeply($data, $content, "$message: content (plain)");
        }
    }

    diag("$message: diag ", explain($data)) if not $ok;

    return $ok;
}
