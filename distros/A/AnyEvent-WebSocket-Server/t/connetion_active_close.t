use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(set_timeout start_server);
use testlib::ConnConfig;
use AnyEvent;
use AnyEvent::WebSocket::Server;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Frame;

set_timeout;

note("--- active close() on the Connection triggers 'finish' event.");

testlib::ConnConfig->for_all_ok_conn_configs(sub {
    my ($cconfig) = @_;
    
    my $cv_finish = AnyEvent->condvar;
    my $server_finish_called = 0;

    my $server = AnyEvent::WebSocket::Server->new($cconfig->server_args);
    my $cv_port = start_server sub {
        my ($fh) = @_;
        $cv_finish->begin;
        $server->establish($fh)->cb(sub {
            my $conn = shift->recv;
            note("server websocket established.");
            $conn->on(finish => sub {
                undef $conn;
                note("server finish event fired.");
                $server_finish_called++;
                $cv_finish->end;
            });
            $conn->close();
        });
    };
    my $port = $cv_port->recv;

    my $hs = Protocol::WebSocket::Handshake::Client->new(url => $cconfig->connect_url($port, "/"));
    my $client_recv_frame = Protocol::WebSocket::Frame->new;
    my @client_recv_messages = ();
    my $client; $client = AnyEvent::Handle->new(
        $cconfig->client_handle_args($port),
        on_error => sub { fail("client handle error: $_[2]") },
        on_connect => sub {
            my ($handle) = @_;
            $cv_finish->begin;
            $handle->push_write($hs->to_string);
        },
        on_read => sub {
            my ($handle) = @_;
            if(!$hs->is_done) {
                $hs->parse($handle->{rbuf});
            }
            if($hs->is_done) {
                $client_recv_frame->append($handle->{rbuf});
                while(defined(my $message = $client_recv_frame->next_bytes)) {
                    my $opcode = $client_recv_frame->opcode;
                    push(@client_recv_messages, { opcode => $opcode, message => $message });
                    if($opcode == 8) {
                        $handle->push_write(Protocol::WebSocket::Frame->new(opcode => $opcode, buffer => $message));
                        note("client received 'close' frame. it sends back the 'close' and waits for the server to close the TCP.");
                    }
                }
            }
        },
        on_eof => sub {
            note("client TCP connection closed gracefully.");
            $cv_finish->end;
            undef $client; ## close the full connection. this is the expected behavior on any end-point, right?
        }
    );

    $cv_finish->recv;
    is($server_finish_called, 1, "server 'finish' callback is called once in response to active close.");
    is(scalar(@client_recv_messages), 1, "client received 1 message");
    is($client_recv_messages[0]{opcode}, 8, "... and it's 'close' frame (frame body is irrelevant).");
});

done_testing;
