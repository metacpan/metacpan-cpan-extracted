#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::X509::TrustAnchors;
use Crypt::Bear::SSL::PrivateCertificate;

use Crypt::Bear::SSL::Client;
use Crypt::Bear::SSL::Server;

my $anchors = Crypt::Bear::X509::TrustAnchors->new->load_file('t/server.crt');
my $private_certificate = Crypt::Bear::SSL::PrivateCertificate->load('t/server.crt', 't/server.key');

ok $anchors;
is $anchors->count, 1;
ok $private_certificate;
is $private_certificate->chain->count, 1;

my $client = Crypt::Bear::SSL::Client->new($anchors);
my $server = Crypt::Bear::SSL::Server->new($private_certificate);

ok $client;
ok $server;
ok $client->reset('server');
ok $server->reset;

is $client->last_error, 'ok';
is $server->last_error, 'ok';

ok eval {
	my $count = 0;
	while (!$client->send_ready) {
		die 'Client is dead: ' . $client->last_error if $client->is_closed;
		die 'Server is dead: ' . $server->last_error if $server->is_closed;
		my $to_server = $client->pull_send;
		$server->push_received($to_server);

		my $to_client = $server->pull_send;
		$client->push_received($to_client);

		die if $count++ > 100;
	}
	1;
};

my $payload1 = 'Hello world!';
my $rec1 = $client->push_send($payload1, !!1);
my $decoded1 = $server->push_received($rec1);
is $decoded1, $payload1;

my $payload2 = 'Welcome back';
my $rec2 = $server->push_send($payload2, !!1);
my $decoded2 = $client->push_received($rec2);
is $decoded2, $payload2;

$client->close;
is $server->push_received($client->pull_send), '';
is $client->push_received($server->pull_send), '';
ok $server->is_closed;
ok $client->is_closed;

done_testing;
