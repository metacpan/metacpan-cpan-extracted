use strict;
use warnings;
use Test::Requires qw(Test::HTTP::Server);
use Test::More tests => 2;
use App::Sysadmin::Log::Simple::HTTP;

my $server = Test::HTTP::Server->new;
sub Test::HTTP::Server::Request::log { 1 }

my $logger = new_ok('App::Sysadmin::Log::Simple::HTTP' => [
    app => {
        http => {
            uri => $server->uri . 'log',
            method => 'post',
        },
        do_http => 1,
        user => 'test',
    },
]);

my $logged = $logger->log(rand);
is $logged => sprintf('Logged to %s via %s', $server->uri . 'log', 'POST')
    or diag explain $logged;
