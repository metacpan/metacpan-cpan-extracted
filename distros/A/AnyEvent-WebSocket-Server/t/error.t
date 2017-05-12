use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout);
use testlib::ConnConfig;
use AnyEvent::WebSocket::Server;
use Try::Tiny;
use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Frame;
use AnyEvent::Handle;

set_timeout;

sub establish_error_case {
    my (%args) = @_;
    my ($label, $code) = @args{qw(label code)};
    subtest $label, sub {
        if(defined($args{skip})) {
            plan skip_all => $args{skip};
        }
        testlib::ConnConfig->for_all_ok_conn_configs(sub {
            my ($cconfig) = @_;
            my $cv_finish = AnyEvent->condvar;
    
            my $server = AnyEvent::WebSocket::Server->new($cconfig->server_args);
            my $cv_port = start_server sub {
                my ($fh) = @_;
                $server->establish($fh)->cb(sub {
                    my $cv_conn = shift;
                    try {
                        $cv_conn->recv;
                        fail("establish() should fail");
                        $cv_finish->croak("establish() should fail");
                    }catch {
                        my $e = shift;
                        $cv_finish->send($e, $fh);
                    };
                });
            };
            my $port = $cv_port->recv;
            $code->($cv_finish, $port, $cconfig);
        });
    };
}

subtest "give undef as fh", sub {
    my $server = AnyEvent::WebSocket::Server->new;
    my $cv_conn = $server->establish(undef);
    try {
        $cv_conn->recv;
        fail("establish should fail.");
    }catch {
        pass("establish should fail.");
    };
};

establish_error_case(
    label => "client closes the connection while sending the handshake request",
    code => sub {
        my ($cv_finish, $port, $cconfig) = @_;
        my $hs = Protocol::WebSocket::Handshake::Client->new(url => $cconfig->connect_url($port, "/"));
        my $hs_string = $hs->to_string;
        my $hs_partial = substr($hs_string, 0, int(length($hs_string) / 2));
        my $handle = AnyEvent::Handle->new(
            $cconfig->client_handle_args($port),
            on_error => sub { fail("client handle error: $_[2]") },
            on_connect => sub {
                my ($handle) = @_;
                $handle->push_write($hs_partial);
                $handle->push_shutdown();
            }
        );
        $cv_finish->recv;
        pass("server establish should fail");
    }
);

establish_error_case(
    label => "client sends a valid HTTP request (but it's not a WebSocket request)",
    code => sub {
        my ($cv_finish, $port, $cconfig) = @_;
        my $request =
            "GET / HTTP/1.1\r\n" .
            "Host: 127.0.0.1\r\n" .
            "Connection: close\r\n" .
            "\r\n";
        my $got_response = "";
        my $cv_client_finish = AnyEvent->condvar;
        my $handle = AnyEvent::Handle->new(
            $cconfig->client_handle_args($port),
            on_error => sub { fail("client handle error: $_[2]") },
            on_connect => sub {
                my ($handle) = @_;
                $handle->push_write($request);
            },
            on_read => sub {
                my ($handle) = @_;
                $got_response .= $handle->{rbuf};
                $handle->{rbuf} = "";
            },
            on_eof => sub {
                $cv_client_finish->send;
            }
        );
        my ($establish_error, $server_fh) = $cv_finish->recv;
        pass("server establish should fail.");

        if(!$cconfig->is_plain_socket_transport) {
            ## If the connection is not "plain" on the $server_fh, we
            ## cannot resume communication because we cannot access
            ## the TLS context inside the AE::WS::Server (more
            ## specifically, AE::Handle in it). So we just end the
            ## test.
            shutdown $server_fh, 2;
            undef $server_fh;
            $handle->push_shutdown();
            $cv_client_finish->recv;
        }else {
            my $server_handle = AnyEvent::Handle->new(
                fh => $server_fh,
                on_error => sub { fail("server handle error: $_[2]") },
            );
            my $send_response =
                "HTTP/1.1 404 Not Found\r\n" .
                "Connection: close\r\n" .
                "Content-Type: text/plain\r\n" .
                "Content-Length: 9\r\n" .
                "\r\n".
                "Not Found";
            $server_handle->push_write($send_response);
            $server_handle->push_shutdown();
            $cv_client_finish->recv;

            is($got_response, $send_response, "server fh remains intact in this case, so the server can send a valid HTTP response.");
        }
    }
);

establish_error_case(
    label => "client sends a totally irrelevant message, but won't close the connection actively.",
    skip => "because the request parser (external module) is not very strict",
    code => sub {
        my ($cv_finish, $port, $cconfig) = @_;
        my $got_response = "";
        my $cv_client_finish = AnyEvent->condvar;
        my $handle = AnyEvent::Handle->new(
            $cconfig->client_handle_args($port),
            on_error => sub { fail("client handle error: $_[2]") },
            on_connect => sub {
                my ($handle) = @_;
                $handle->push_write("hogehoge");
            },
            on_read => sub {
                my ($handle) = @_;
                $got_response .= $handle->{rbuf};
                $handle->{rbuf} = "";
            },
            on_eof => sub { $cv_client_finish->send },
        );
        my ($server_error, $server_fh) = $cv_finish->recv;
        pass("server establishment should fail");
        
        close($server_fh); ## is it ok just closing the socket even if TLS session is active on it?
        $cv_client_finish->recv;
        is($got_response, "", "server shuts down the connection without sending any data.");
    }
);

## No test for the case "client closes the connection right after
## sending the whole handshake request", because in this case the
## server thinks that the WebSocket connection is established, but
## disconnected immediately.

subtest "After handshake, client disconnects while sending a frame", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        
        my $server = AnyEvent::WebSocket::Server->new($cconfig->server_args);
        my @got_messages = ();
        my $cv_finish = AnyEvent->condvar;
        my $cv_port = start_server sub {
            my ($fh) = @_;
            $server->establish($fh)->cb(sub {
                my ($conn) = shift->recv;
                $conn->on(each_message => sub {
                    my ($conn, $msg) = @_;
                    push(@got_messages, $msg->body);
                });
                $conn->on(finish => sub {
                    undef $conn;
                    $cv_finish->send;
                });
            });
        };
        my $port = $cv_port->recv;
    
        my $hs = Protocol::WebSocket::Handshake::Client->new(url => $cconfig->connect_url($port, "/"));
        my $client = AnyEvent::Handle->new(
            $cconfig->client_handle_args($port),
            on_error => sub { fail("client handle error: $_[2]") },
            on_connect => sub {
                my ($handle) = @_;
                $handle->push_write($hs->to_string);
            },
            on_read => sub {
                my ($handle) = @_;
                if(!$hs->is_done) {
                    $hs->parse($handle->{rbuf});
                    if($hs->is_done) {
                        $handle->push_write(Protocol::WebSocket::Frame->new("Hello, ")->to_bytes);
                        my $world_frame = Protocol::WebSocket::Frame->new("world!")->to_bytes;
                        $handle->push_write(substr($world_frame, 0, 4)); ## partial message
                        $handle->push_shutdown();
                    }
                    return;
                }
                fail("No server sent frame should be received.");
            },
            on_eof => sub {
                note("client disconnected gracefully");
            },
        );

        $cv_finish->recv;
        is_deeply(\@got_messages, ["Hello, "], "only the first message should be received. the partial message should be discarded.");
    });
};

done_testing;

