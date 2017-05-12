use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout);
use testlib::ConnConfig;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;
use Protocol::WebSocket::Handshake::Client;

set_timeout;

sub start_passive_server {
    my ($websocket_server, $finish_cb) = @_;
    $finish_cb ||= sub {};
    my $port_cv = start_server sub {
        my ($fh) = @_;
        $websocket_server->establish($fh)->cb(sub {
            my $conn = shift->recv;
            $conn->on(finish => sub {
                undef $conn;
                $finish_cb->();
            });
        });
    };
    return $port_cv;
}

sub client_connection {
    my ($cconfig, $port, $path) = @_;
    return AnyEvent::WebSocket::Client->new($cconfig->client_args)
        ->connect($cconfig->connect_url($port, $path))->recv;
}

sub get_raw_response {
    my ($cconfig, $port, $path) = @_;
    my $raw_response_cv = AnyEvent->condvar;
    my $hs = Protocol::WebSocket::Handshake::Client->new(url => $cconfig->connect_url($port, $path));
    my $handle; $handle = AnyEvent::Handle->new(
        $cconfig->client_handle_args($port),
        on_error => sub { $raw_response_cv->croak("client handle error: $_[2]"); },
        on_connect => sub {
            my ($handle) = @_;
            $handle->push_write($hs->to_string);
        },
        on_read => sub {
            my ($handle) = @_;
            if($handle->{rbuf} =~ s/^(.+\r\n\r\n)//s) {
                $raw_response_cv->send($1);
                $handle->push_shutdown();
                return;
            }
        },
        on_eof => sub {
            undef $handle;
        }
    );
    return $raw_response_cv;
}

sub handshake_error_case {
    my (%args) = @_;
    my $handshake = $args{handshake};
    my $exp_error_pattern = $args{exp_error_pattern};
    my $label = $args{label};
    subtest $label, sub {
        testlib::ConnConfig->for_all_ok_conn_configs(sub {
            my ($cconfig) = @_;
            my $s = AnyEvent::WebSocket::Server->new(
                $cconfig->server_args,
                handshake => $handshake
            );
            my $finish_cv = AnyEvent->condvar;
            my $port_cv = start_server sub {
                my ($fh) = @_;
                $s->establish($fh)->cb(sub {
                    my ($conn) = eval { shift->recv };
                    like $@, $exp_error_pattern, $label;
                    is $conn, undef;
                    shutdown $fh, 0;
                    undef $fh;
                    $finish_cv->send;
                });
            };
            my $port = $port_cv->recv;
            my $client_conn_cv = AnyEvent::WebSocket::Client->new($cconfig->client_args)
                ->connect($cconfig->connect_url($port, "/hoge"));
            $finish_cv->recv;
            my ($client_conn) = eval { $client_conn_cv->recv };
            is $client_conn, undef, "client connection should not be obtained";
        });
    };
}


subtest "basic IO", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $called = 0;
        my $s = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            handshake => sub {
                my ($req, $res) = @_;
                $called = 1;
                ok wantarray, "handshake should be called in list context";
                isa_ok $req, "Protocol::WebSocket::Request";
                isa_ok $res, "Protocol::WebSocket::Response";
                return $res;
            }
        );
        my $finish_cv = AnyEvent->condvar;
        my $port = start_passive_server($s, sub { $finish_cv->send })->recv;
        my $client_conn = client_connection($cconfig, $port, "/websocket");
        $client_conn->close;
        $finish_cv->recv;
        ok $called;
    });
};

subtest "handshake is called for each request", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my @resource_names = ();
        my $s = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            handshake => sub {
                my ($req, $res) = @_;
                push @resource_names, $req->resource_name;
                return $res;
            }
        );
        my $finish_cv;
        my $port = start_passive_server($s, sub { $finish_cv->send })->recv;
        foreach my $path (
            "/", "/foo", "/foo/bar"
        ) {
            @resource_names = ();
            $finish_cv = AnyEvent->condvar;
            my $client_conn = client_connection($cconfig, $port, $path);
            $client_conn->close;
            $finish_cv->recv;
            is_deeply \@resource_names, [$path], "request resource name should be '$path'";
        }
    });
};

subtest "other_results", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $s = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            handshake => sub {
                my ($req, $res) = @_;
                return ($res, "hoge", 256, $res->resource_name);
            }
        );
        my @got_other_results = ();
        my $finish_cv = AnyEvent->condvar;
        my $port_cv = start_server sub {
            my ($fh) = @_;
            $s->establish($fh)->cb(sub {
                my ($conn, @other_results) = shift->recv;
                push @got_other_results, @other_results;
                $conn->on(finish => sub {
                    undef $conn;
                    $finish_cv->send;
                });
            });
        };
        my $port = $port_cv->recv;
        my $client_conn = client_connection($cconfig, $port, "/HOGE");
        $client_conn->close;
        $finish_cv->recv;
        is_deeply \@got_other_results, ["hoge", 256, "/HOGE"];
    });
};

subtest "response with subprotocol", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $s = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            handshake => sub {
                my ($req, $res) = @_;
                $res->subprotocol("mytest.subprotocol");
                return $res;
            }
        );
        my $finish_cv = AnyEvent->condvar;
        my $port = start_passive_server($s, sub { $finish_cv->send })->recv;
        my $raw_res = get_raw_response($cconfig, $port, "/hogehoge")->recv;
        $finish_cv->recv;
        note("Response:");
        note($raw_res);
        like $raw_res, qr{^HTTP/1\.[10] 101}i, "101 status line OK";
        like $raw_res, qr{^Sec-WebSocket-Protocol\s*:\s*mytest\.subprotocol}im, "subprotocol is set OK";
    });
};

subtest "raw response", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $input_response = "This must be rejected by the client\r\n\r\n";
        my $s = AnyEvent::WebSocket::Server->new(
            $cconfig->server_args,
            handshake => sub {
                my ($req, $res) = @_;
                return "This must be rejected by the client\r\n\r\n";
            }
        );
        my $finish_cv = AnyEvent->condvar;
        my $port = start_passive_server($s, sub { $finish_cv->send })->recv;
        my $raw_res = get_raw_response($cconfig, $port, "/foobar")->recv;
        $finish_cv->recv;
        note("Response:");
        note($raw_res);
        is $raw_res, $input_response, "raw response OK";
    });
};

handshake_error_case(
    label => "throw exception",
    handshake => sub { die "BOOM!" },
    exp_error_pattern => qr/BOOM\!/,
);

handshake_error_case(
    label => "no return",
    handshake => sub { return () },
    exp_error_pattern => qr/handshake response was undef/i,
);

done_testing;
