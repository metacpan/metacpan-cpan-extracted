#! perl -I. -w
use t::Test::abeltje;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'test';
    $ENV{DANCER_APPDIR}      = '.';
}

use Dancer2 qw/:syntax !pass !warning/;
use Plack::Test;

use HTTP::Request;
use RPC::XML::ParserFactory;
use Dancer2::RPCPlugin::DefaultRoute;
use Dancer2::Plugin::RPC::JSONRPC;
use Dancer2::Plugin::RPC::XMLRPC;
use Dancer2::Plugin::RPC::RESTRPC;

use MyTest::API;
use MyTest::Client;

my $client = MyTest::Client->new(ping_value => 'pong');
my $dispatch = {
    'MyTest::API' => MyTest::API->new(test_client => $client),
};
my $config = {
    publish      => 'config',
    code_wrapper => sub {
        my ($code, $package, $method) = splice(@_, 0, 3);
        my $instance = $dispatch->{$package};
        $instance->$code(@_);
    },
};

set(
    logger => 'null',
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

my $app = main->to_app();
my $tester = Plack::Test->create($app);

note("Send request to the *working* app without catch-all");
{
    my $request = HTTP::Request->new(
        POST => '/jsonrpc',
        ['Content-Type' => 'application/json'],
        as_jsonrpc('ping'),
    );
    my $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'application/json',
        {result => 'pong'},
        "ok(jsonrpc: ping)"
    );

    $request = HTTP::Request->new(
        POST => '/xmlrpc',
        ['content-type' => 'text/xml'],
        as_xmlrpc('ping'),
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'text/xml',
        {result => 'pong'},
        "ok(xmlrpc: ping)"
    );

    $request = HTTP::Request->new(
        POST => '/restrpc/ping',
        [ 'content-type' => 'application/json' ],
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'application/json',
        {result => 'pong'},
        "ok(restrpc: ping)"
    );
}

note("Send *rubbish* to the working app **without** catch-all");
{
    my $request = HTTP::Request->new(
        POST => '/jsonrpc',
        [ 'content-type' => 'application/rubbish' ],
        as_jsonrpc('ping'),
    );
    my $response = $tester->request($request);
    is($response->status_line, '404 Not Found', "URI not found for content-type(jsonrpc)");
    is($response->content_type, 'text/html', "Content-Type set to html");

    $request = HTTP::Request->new(
        POST => '/xmlrpc',
        [ 'content-type' => 'application/rubbish' ],
        as_xmlrpc('ping'),
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '404 Not Found',
        'text/html',
        qr{Error 404 - Not Found}
    );

    $request = HTTP::Request->new(
        POST => '/restrpc/ping',
        [ content_type => 'application/rubbish' ],
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '404 Not Found',
        'text/html',
        qr{Error 404 - Not Found}
    );
}

ok(setup_default_route(),"setting the catchall route");
#any qr{.+} => sub { error(">>>>>>>>>>>>>>>>>>", \@_); pass };
$app = main->to_app();
$tester = Plack::Test->create($app);

note("Send *rubbish* to the working app **with** catch-all");
{

    my $request = HTTP::Request->new(
        POST => '/jsonrpc',
        [ 'content-type' => 'application/rubbish' ],
        as_jsonrpc('ping'),
    );
    my $response = $tester->request($request);
    response_contains_ok(
        $response,
        '404 Not Found',
        'text/plain',
        "Error! '/jsonrpc' was not found for 'application/rubbish'",
    );

    $request = HTTP::Request->new(
        POST => '/rubbish',
        [
            content_type => 'application/json',
            accept       => 'application/json',
        ],
        as_jsonrpc('ping'),
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'application/json',
        {
            code    => -32601,
            message => "Method 'ping' not found at '/rubbish'",
        }
    );

    $request = HTTP::Request->new(
        POST => '/rubbish',
        [ content_type => 'text/xml' ],
        as_xmlrpc('ping'),
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'text/xml',
        {
            faultCode   => -32601,
            faultString => "Method 'ping' not found at '/rubbish'",
        }
    );

    $request = HTTP::Request->new(
        POST => '/rubbish/ping',
        [
            content_type => 'application/json',
            accept       => 'application/json',
        ],
        '',    #to_json(undef, {allow_nonref => 1}),
    );
    $response = $tester->request($request);
    response_contains_ok(
        $response,
        '200 OK',
        'application/json',
        {
            error => {
                code    => -32601,
                message => "Method 'ping' not found",
            }
        }
    );
}

abeltje_done_testing();

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
        $response->status_line,
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
