use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout);
use testlib::ConnConfig;
use AnyEvent;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;

set_timeout;

testlib::ConnConfig->for_all_ok_conn_configs(sub {
    my ($cconfig) = @_;
    my $server = AnyEvent::WebSocket::Server->new($cconfig->server_args);
    my $connection_num = 0;
    my $cv_finish = AnyEvent->condvar;

    my $cv_port = start_server sub {
        my ($fh) = @_;
        $server->establish($fh)->cb(sub {
            my ($conn) = shift->recv;
            $cv_finish->begin;
            $connection_num++;
            $conn->on(finish => sub {
                undef $conn;
                $connection_num--;
                $cv_finish->end;
            });
        });
    };
    my $port = $cv_port->recv;

    my $TRY_NUM = 50;
    my $client = AnyEvent::WebSocket::Client->new($cconfig->client_args);
    my @conns = ();

    foreach (1 .. $TRY_NUM) {
        my $conn = $client->connect($cconfig->connect_url($port, "/"))->recv;
        push(@conns, $conn);
    }

    is($connection_num, $TRY_NUM, "$TRY_NUM connections are kept alive.");

    foreach my $conn (@conns) {
        $conn->close();
    }

    $cv_finish->recv;
    is($connection_num, 0, "no connections");
});


done_testing;
