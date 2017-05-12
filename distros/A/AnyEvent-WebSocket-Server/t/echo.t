use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout memory_cycle_ok memory_cycle_exists);
use testlib::ConnConfig;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;
no utf8;

set_timeout;

testlib::ConnConfig->for_all_ok_conn_configs(sub {
    my ($cconfig) = @_;
    
    my @server_conns = ();
    my $cv_server_finish = AnyEvent->condvar;

    my $cv_port = start_server sub { ## accept cb
        my ($fh) = @_;
        note("TCP connection accepted");
        AnyEvent::WebSocket::Server->new($cconfig->server_args)->establish($fh)->cb(sub {
            my ($conn, @values) = shift->recv;
            $cv_server_finish->begin;
            push(@server_conns, $conn);
            isa_ok($conn, "AnyEvent::WebSocket::Connection");
            is(scalar(@values), 0, "empty validator results");
            $conn->on(each_message => sub {
                my ($conn, $message) = @_;
                $conn->send($message);
            });
            $conn->on(finish => sub {
                undef $conn;    ## make the connection half-immortal
                $cv_server_finish->end;
            });
        });
    };

    note("TCP connect...");
    my $connect_port = $cv_port->recv;
    note("TCP port $connect_port opend.");
    my $client_conn = AnyEvent::WebSocket::Client->new($cconfig->client_args)
        ->connect($cconfig->connect_url($connect_port, "/websocket"))->recv;
    note("Client connection established.");

    foreach my $case (
        {label => "0 bytes", data => ""},
        {label => "10 bytes", data => "a" x 10},
        {label => "256 bytes", data => "a" x 256},
        {label => "zero", data => "0"},
        {label => "encoded UTF-8", data => 'ＵＴＦー８ＷｉｄｅＣｈａｒａｃｔｅｒｓ'},
    ) {
        my $cv_received = AnyEvent->condvar;
        $client_conn->on(next_message => sub {
            my ($c, $message) = @_;
            $cv_received->send($message->body);
        });
        $client_conn->send($case->{data});
        is($cv_received->recv, $case->{data}, "$case->{label}: echo OK");
    }

    is(scalar(@server_conns), 1, "1 server connection");
    memory_cycle_exists($server_conns[0], "memory cycle on Connection at 'finish' event handler, which makes the Connection half-immortal");

    $client_conn->close();
    $cv_server_finish->recv;

    memory_cycle_ok($server_conns[0], "free of memory cycle on Connection. Now it's mortal.");
});


done_testing;
