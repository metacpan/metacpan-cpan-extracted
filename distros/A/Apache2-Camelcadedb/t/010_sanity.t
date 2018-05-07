use strict;
use warnings;
use threads;
use threads::shared;

use Test::More tests => 5;
use Apache::TestRequest;
use IO::Socket::INET;
use JSON::XS;

my $listen_address = do {
    open my $fh, 't/logs/camelcade_port.txt'
        or die "Error opening 't/logs/camelcade_port.txt': $!";
    scalar readline $fh;
};
my $fake_dbg = IO::Socket::INET->new(
    LocalAddr => $listen_address,
    ReusePort => 1,
    Listen    => 5,
);
die "Unable to set up debugger socket: $!" unless $fake_dbg;

my @events :shared;

sub accept_debugger {
    my $remote = $fake_dbg->accept;

    push @events, 'debugger_open';

    my $json_text = $remote->getline;
    my $data = JSON::XS->new->allow_nonref->decode($json_text);

    is($data->{event}, "READY", "debugger handshake sanity check");
    sleep 1;

    push @events, 'debugger_close';
    $remote->close;

    1;
}

sub make_request {
    push @events, 'request_send';

    my $res = GET "/hello";
    is($res->content, "Hello, world!\n");

    push @events, 'response_received';

    1;
}

my $dbg_thread = threads->create(\&accept_debugger);
my $req_thread = threads->create(\&make_request);

ok($req_thread->join, "request thread completed succesfully");
ok($dbg_thread->join, "debugger thread completed successfully");

is_deeply(
    \@events,
    [qw(request_send debugger_open debugger_close response_received)],
    "debugger is blocking request execution",
);
