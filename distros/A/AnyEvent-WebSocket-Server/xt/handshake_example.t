use strict;
use warnings;
use Test::More;
use FindBin;
use lib ("$FindBin::RealBin/../t");
use testlib::Util qw(set_timeout);
use AnyEvent::WebSocket::Client;
use AnyEvent;

set_timeout;

sub error_response {
    my ($fh, $error) = @_;
    close($fh);
}

###############

use AnyEvent::Socket qw(tcp_server);
use AnyEvent::WebSocket::Server;

my $server = AnyEvent::WebSocket::Server->new(
    handshake => sub {
        my ($req, $res) = @_;
        ## $req is a Protocol::WebSocket::Request
        ## $res is a Protocol::WebSocket::Response

        ## validating and parsing request.
        my $path = $req->resource_name;
        die "Invalid format" if $path !~ m{^/(\d{4})/(\d{2})};
        
        my ($year, $month) = ($1, $2);
        die "Invalid month" if $month <= 0 || $month > 12;

        ## setting WebSocket subprotocol in response
        $res->subprotocol("mytest");
        
        return ($res, $year, $month);
    }
);

tcp_server undef, 8080, sub {
    my ($fh) = @_;
    $server->establish($fh)->cb(sub {
        my ($conn, $year, $month) = eval { shift->recv };
        if($@) {
            my $error = $@;
            error_response($fh, $error);
            return;
        }
        $conn->send("You are accessing YEAR = $year, MONTH = $month");
        $conn->on(finish => sub { undef $conn });
    });
};

###############

my $client = AnyEvent::WebSocket::Client->new;
my $conn = $client->connect("ws://127.0.0.1:8080/2013/10")->recv;
note("Client connection established");
my $cv_finish = AnyEvent->condvar;

$conn->on(each_message => sub {
    my ($conn, $message) = @_;
    $cv_finish->send($message->body);
});

is($cv_finish->recv, "You are accessing YEAR = 2013, MONTH = 10", "message OK");

done_testing;
