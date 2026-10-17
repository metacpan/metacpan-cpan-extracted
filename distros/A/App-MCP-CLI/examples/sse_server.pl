#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Status;
use JSON::MaybeXS;

my $HOST = $ENV{SSE_HOST} || "127.0.0.1";
my $PORT = $ENV{SSE_PORT} || 8080;

my $d = HTTP::Daemon->new(
    LocalAddr => $HOST,
    LocalPort => $PORT,
    ReuseAddr => 1
) or die "Failed to start mock server: $!";

print "[-] Mock MCP SSE Server listening at: http://$HOST:$PORT/sse\n";
print "[-] Press Ctrl+C to stop the server.\n\n";

my $json = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {

        # Server-Sent Events channel
        if ($r->method eq 'GET' && $r->uri->path eq '/sse') {
            print "[Server] Received SSE connection handshake request.\n";

            my $res = HTTP::Response->new(RC_OK);
            $res->header('Content-Type'  => 'text/event-stream');
            $res->header('Cache-Control' => 'no-cache');
            $res->header('Connection'    => 'keep-alive');

            $res->content("event: endpoint\ndata: http://$HOST:$PORT/message\n\n");

            $c->send_response($res);
            print "[Server] Broadcasted dynamic endpoint to client. Channel open.\n";
        }
        elsif ($r->method eq 'POST' && $r->uri->path eq '/message') {
            my $raw_content = $r->content;
            my $payload     = eval { $json->decode($raw_content) };

            if ($@ || !$payload) {
                print "[Server] Error parsing incoming client JSON request: $@\n";
                $c->send_error(RC_BAD_REQUEST);
                next;
            }

            my $method = $payload->{method} // '';
            my $id     = $payload->{id}     // 1;
            print "[Server] Received Client Request -> Method: '$method' (ID: $id)\n";

            my $response_data = {
                jsonrpc => "2.0",
                id      => $id
            };

            if ($method eq 'initialize') {
                $response_data->{result} = {
                    protocolVersion => "2024-11-05",
                    capabilities    => {},
                    serverInfo      => { name => "mock-perl-sse-server", version => "1.0.0" }
                };
            }
            elsif ($method eq 'tools/list') {
                $response_data->{result} = {
                    tools => [
                        {
                            name        => "get_mock_weather",
                            description => "Returns static mock weather information for a location.",
                            inputSchema => {
                                type       => "object",
                                properties => { location => { type => "string" } },
                                required   => ["location"]
                            }
                        }
                    ]
                };
            }
            elsif ($method eq 'tools/call') {
                my $tool_name = $payload->{params}{name} // '';
                print "[Server] Tool invocation requested for: $tool_name\n";

                $response_data->{result} = {
                    content => [
                        {
                            type => "text",
                            text => "The weather in that area is currently 21°C and clear skies."
                        }
                    ]
                };
            }
            else {
                $response_data->{result} = { status => "unsupported method stub" };
            }

            my $res = HTTP::Response->new(RC_OK);
            $res->header('Content-Type' => 'application/json');
            $res->content($json->encode($response_data));
            $c->send_response($res);
        }
        else {
            print "[Server] 404 Route Unrecognized: " . $r->method . " " . $r->uri->path . "\n";
            $c->send_error(RC_NOT_FOUND);
        }
    }

    $c->close;
    undef $c;
}

1;
