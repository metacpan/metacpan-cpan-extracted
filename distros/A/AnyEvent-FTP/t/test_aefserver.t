use strict;
use warnings;
use Test::More tests => 18;
use Test::AnyEventFTPServer;

global_timeout_ok;

my $server = create_ftpserver_ok;
isa_ok $server, 'AnyEvent::FTP::Server';
isa_ok $server->test_uri, 'URI';

my $client = $server->connect_ftpclient_ok;
isa_ok $client, 'AnyEvent::FTP::Client';

my $response = $client->help->recv;
is $response->code, 214, "help response code = 214";

$response = $client->quit->recv;
is $response->code, 221, "quit response code = 221";

$server->help_coverage_ok;

$server->command_ok('bogus')
       ->code_is(500)
       ->code_like(qr{5..})
       ->message_like(qr{not understood});

$server->command_ok('HELP')
       ->code_is(214)
       ->code_like(qr{.1.})
       ->message_like(qr{The following commands are recognized});

isa_ok $server->res, 'AnyEvent::FTP::Client::Response';

