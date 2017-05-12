#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

print "[Server $0 starting up]\n";

require CGI::Portable;
my $globals = CGI::Portable->new();

use Cwd;
$globals->file_path_root( cwd() );  # let us default to current working directory
$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

$globals->set_prefs( 'config.pl' );
$globals->current_user_path_level( 1 );

require CGI::Portable::AdapterSocket;
my $io = CGI::Portable::AdapterSocket->new();

use IO::Socket;
my $server = IO::Socket::INET->new(
	Listen    => SOMAXCONN,
	LocalAddr => '127.0.0.1',
	LocalPort => 1984,
	Proto     => 'tcp'
);
die "[Error: can't setup server $0]" unless $server;

print "[Server $0 accepting clients]\n";

while( my $client = $server->accept() ) {
	printf "%s: [Connect from %s]\n", scalar localtime, $client->peerhost;

	my $content = $globals->make_new_context();

	$io->fetch_user_input( $content, $client );
	$content->call_component( 'DemoAardvark' );
	$io->send_user_output( $content, $client );

	close $client;

	printf "%s http://%s:%s%s %s\n", $content->request_method, 
		$content->server_domain, $content->server_port, 
		$content->user_path_string, $content->http_status_code;
}

1;
