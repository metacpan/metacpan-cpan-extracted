use strict;
use warnings;
use Test::More;
use FindBin;
use lib ("$FindBin::RealBin/../t");
use testlib::Util qw(start_server set_timeout);
use AnyEvent::WebSocket::Server;

if(!$ENV{ANYEVENT_WEBSOCKET_SERVER_BROWSER_TEST}) {
    plan skip_all => "Set environment variable ANYEVENT_WEBSOCKET_SERVER_BROWSER_TEST=1 to run the browser test.";
}

my $TIMEOUT = 30;
set_timeout($TIMEOUT);

my $server = AnyEvent::WebSocket::Server->new(max_payload_size => 256 * 1024);
my $cv_finish = AnyEvent->condvar;

my $cv_port = start_server 18888, sub {
    my ($fh) = @_;
    note("Connection established");
    $server->establish($fh)->cb(sub {
        my $conn = shift->recv;
        $conn->on(each_message => sub {
            my ($inner_conn, $msg) = @_;
            my $size = length($msg->body);
            note("Message received: $size bytes");
            if($msg->body eq "QUIT") {
                $inner_conn->close();
            }elsif($msg->body eq "UNDEF") {
                undef $conn;
            }elsif($msg->body eq "DONE_TESTING") {
                note("DONE_TESTING received");
                $inner_conn->close();
                $cv_finish->send;
            }else {
                $inner_conn->send($msg);
            }
        });
        $conn->on(finish => sub {
            note("Finish");
            undef $conn;
        });
        $conn->send("connected");
    });
};

my $port = $cv_port->recv;
diag("Now connect to file://$FindBin::RealBin/js/browser.html within $TIMEOUT seconds!");

$cv_finish->recv;
pass;

done_testing;
