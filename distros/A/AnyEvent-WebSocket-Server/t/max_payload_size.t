use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout);
use testlib::ConnConfig;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;

set_timeout;

my $BIG_MAX_SIZE =  99999;
my $BIG_DATA_SIZE = 99900;

subtest "server sends a big frame", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $finish_cv = AnyEvent->condvar;
        my $DATA = "a" x $BIG_DATA_SIZE;
        my $port_cv = start_server sub {
            my ($fh) = @_;
            AnyEvent::WebSocket::Server->new(
                $cconfig->server_args,
            )->establish($fh)->cb(sub {
                my ($conn) = shift->recv;
                $conn->on(finish => sub {
                    undef $conn;
                    $finish_cv->send;
                });
                $conn->send($DATA);
            });
        };
        my $connect_port = $port_cv->recv;
        my $client_conn = AnyEvent::WebSocket::Client->new(
            $cconfig->client_args,
            max_payload_size => $BIG_MAX_SIZE
        )->connect($cconfig->connect_url($connect_port, "/websocket"))->recv;
        $client_conn->on(next_message => sub {
            my ($c, $message) = @_;
            is $message->body, $DATA;
            $c->close;
        });
        $finish_cv->recv;
    });
};

subtest "server receives a big frame", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $finish_cv = AnyEvent->condvar;
        my $receive_cv = AnyEvent->condvar;
        my $DATA = "a" x $BIG_DATA_SIZE;
        my $port_cv = start_server sub {
            my ($fh) = @_;
            AnyEvent::WebSocket::Server->new(
                $cconfig->server_args,
                max_payload_size => $BIG_MAX_SIZE
            )->establish($fh)->cb(sub {
                my ($conn) = shift->recv;
                $conn->on(next_message => sub {
                    my ($c, $message) = @_;
                    $receive_cv->send($message->body);
                });
                $conn->on(finish => sub {
                    undef $conn;
                    $finish_cv->send;
                });
            });
        };
        my $connect_port = $port_cv->recv;
        my $client_conn = AnyEvent::WebSocket::Client->new(
            $cconfig->client_args,
        )->connect($cconfig->connect_url($connect_port, "/websocket"))->recv;
        $client_conn->send($DATA);
        $client_conn->close;
        is $receive_cv->recv, $DATA;
        $finish_cv->recv;
    });
};


subtest "server connection emits parse_error event when receiving bigger frame than the default limit", sub {
    testlib::ConnConfig->for_all_ok_conn_configs(sub {
        my ($cconfig) = @_;
        my $parse_error_emitted = 0;
        my $port_cv = start_server sub {
            my ($fh) = @_;
            AnyEvent::WebSocket::Server->new(
                $cconfig->server_args,
            )->establish($fh)->cb(sub {
                my ($conn) = shift->recv;
                $conn->on(parse_error => sub {
                    $parse_error_emitted++;
                });
                $conn->on(finish => sub {
                    undef $conn;
                });
            });
        };
        my $connect_port = $port_cv->recv;
        my $client_conn = AnyEvent::WebSocket::Client->new(
            $cconfig->client_args,
        )->connect($cconfig->connect_url($connect_port, "/websocket"))->recv;
        my $finish_cv = AnyEvent->condvar;
        $client_conn->on(finish => sub {
            $finish_cv->send;
        });
        $client_conn->send("*" x ($BIG_DATA_SIZE * 2));
        $finish_cv->recv;
        cmp_ok $parse_error_emitted, ">", 0, "parse_error event is emitted";
    });
};

done_testing;
