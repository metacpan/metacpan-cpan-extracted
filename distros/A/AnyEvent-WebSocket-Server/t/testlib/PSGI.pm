package testlib::PSGI;
use strict;
use warnings;
use Test::More;
use Test::Requires {
    "Net::EmptyPort" => "0",
    "AnyEvent::HTTP" => "0",
};
use testlib::Util qw(set_timeout);
use testlib::ConnConfig;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;
use Net::EmptyPort qw(empty_port);
use AnyEvent::HTTP qw(http_get);
use Try::Tiny;
use Exporter qw(import);

our @EXPORT_OK = qw(run_tests);

my $cv_server_finish;
    
sub _make_app {
    my ($ws_server) = @_;
    return sub {
        my ($env) = @_;
        return sub {
            my $responder = shift;
            note("server enters streaming callback");
            $cv_server_finish->begin;
            $ws_server->establish_psgi($env)->cb(sub {
                my $cv = shift;
                my ($conn, $validate_str) = try { $cv->recv };
                if(!$conn) {
                    note("server connection error");
                    $responder->([400, ['Content-Type' => 'text/plain', 'Connection' => 'close'], ['invalid request']]);
                    $cv_server_finish->end;
                    return;
                }
                note("server websocket established");
                is($validate_str, "validated", "validator should be called");
                $conn->on(each_message => sub {
                    my ($conn, $message) = @_;
                    $conn->send($message);
                });
                $conn->on(finish => sub {
                    undef $conn;
                    $cv_server_finish->end;
                    ## release the session held by the PSGI server.
                    $responder->([200, ['Content-Type' => 'text/plain', 'Connection' => 'close'], ['dummy response']]);
                });
            });
        };
    };
}

sub _test_case {
    my ($label, $code) = @_;
    subtest $label, sub {
        $cv_server_finish = AnyEvent->condvar;
        $code->();
    };
}

sub run_tests {
    my ($server_runner) = @_;
    set_timeout;
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        if(!$cconfig->is_plain_socket_transport($cconfig)) {
            my $label = $cconfig->label;
            plan skip_all => "Case '$label' does not use a plain socket. Too unrealistic to test. Skipped.";
        }
        my $client = AnyEvent::WebSocket::Client->new($cconfig->client_args);
        my $server = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            validator => sub { return "validated" }
        );
        my $port = empty_port();
        note("empty port: $port");
        my $server_guard = $server_runner->($port, _make_app($server));
    
        _test_case "normal echo", sub {
            my $conn = $client->connect($cconfig->connect_url($port, "/"))->recv;
            note("client connection established");
            my @received = ();
            $cv_server_finish->begin;
            $conn->on(each_message => sub {
                push(@received, $_[1]->body);
            });
            $conn->on(finish => sub {
                $cv_server_finish->end;
            });
            $conn->send("foobar");
            $conn->close;
            $cv_server_finish->recv;
            pass("server connection shutdown");
            is_deeply(\@received, ["foobar"], "received message OK");
        };

        _test_case "http fallback", sub {
            my $cv_client = AnyEvent->condvar;
            http_get "http://127.0.0.1:$port/", sub { $cv_client->send(@_) };
            note("send http request");
            my ($data, $headers) = $cv_client->recv;
            is($headers->{Status}, 400, "response status code OK");
            is($data, "invalid request", "response data OK");
            $cv_server_finish->recv;
            pass("server session finished");
        };
    });
}

1;
