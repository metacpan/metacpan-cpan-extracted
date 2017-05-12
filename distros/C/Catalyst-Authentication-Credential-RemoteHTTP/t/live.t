use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "HTTP::Server::Simple is required for this test"
      unless eval { require HTTP::Server::Simple };
    plan skip_all => "Catalyst::Authentication::Store::Minimal is required for this test"
      unless eval { require Catalyst::Authentication::Store::Minimal };
    plan "no_plan";
}

use lib 't/lib';
use TestWebServer;
use Catalyst::Test qw/AuthTestApp/;

# get a port to test against - we check its OK later
my $port = 10763;    # this must match config in AuthTestApp.pm

# this test should be run *without* the authenticating server
ok( get("/testnotworking"), "get ok" );

SKIP: {
    eval { require IO::Socket::INET };
    skip "IO::Socket::INET not installed" if $@;

    my $remote = IO::Socket::INET->new(
        Listen =>5,
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    my $check = $remote ? 1 : 0;
    close $remote if ($check);

    skip "TCP port $port not available for tests" unless ($check);

    ok( $check, "TCP port $port is available for testing" );

    my $pid = TestWebServer->new($port)->background;
    ok( $pid, 'Start authenticating web server' );
    sleep(1);    # give it time to start

    # this test should be run *with* the authenticating server
    ok( get("/testworking"), "get ok" );

    # and kill off the test web server
    kill 9, $pid;
}
