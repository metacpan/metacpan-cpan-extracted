use strict;
use warnings;
use Test::More;
use AnyEvent;
use AnyEvent::WebSocket::Server;
use AnyEvent::WebSocket::Client;
use Try::Tiny;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::ConnConfig;
use testlib::Util qw(set_timeout start_server);

note("unmatched client/server connection");

set_timeout;

testlib::ConnConfig->for_all_ng_conn_configs(sub {
    my ($cconfig) = @_;
    my $server = AnyEvent::WebSocket::Server->new($cconfig->server_args);
    my $server_conn_cv = AnyEvent->condvar;
    my $port_cv = start_server sub {
        my ($fh) = @_;
        $server->establish($fh)->cb(sub {
            my ($cv) = @_;
            undef $fh;
            try {
                $cv->recv;
                $server_conn_cv->send(undef);
            }catch {
                my ($e) = @_;
                $server_conn_cv->send($e);
            }
        });
    };
    my $port = $port_cv->recv;
    my $client_conn_cv = AnyEvent::WebSocket::Client->new($cconfig->client_args)->connect($cconfig->connect_url($port, "/websocket"));
    my $client_ret = try {
        $client_conn_cv->recv;
        undef;
    }catch {
        my ($e) = @_;
        $e;
    };
    my $server_conn_error = $server_conn_cv->recv;
    isnt $server_conn_error, undef, "server conn should throw exception";
    note("server_conn_error was:");
    note($server_conn_error);
    note("client_conn_cv returned this:");
    note(defined($client_ret) ? $client_ret : "<undef>");
});

done_testing;
