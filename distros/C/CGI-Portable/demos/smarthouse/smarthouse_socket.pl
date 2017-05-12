#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

# SmartHouse - A Web-based X10 Device Controller in Perl.
# This demo is based on a college lab assignment.  It doesn't actually 
# control any hardware, but is a simple web interface for such a program 
# should one want to extend it in that manner.  This is meant to show how 
# CGI::Portable can be used in a wide variety of environments, not just 
# ordinary database or web sites.  If you wanted to extend it then you 
# should use modules like ControlX10::CM17, ControlX10::CM11, or 
# Device::SerialPort.  On the other hand, if you want a very complete 
# (and complicated) Perl solution then you can download Bruce Winter's 
# free open-source MisterHouse instead at "http://www.misterhouse.net".

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
	$content->call_component( 'DemoX10' );
	$io->send_user_output( $content, $client );

	close $client;

	printf "%s http://%s:%s%s %s\n", $content->request_method, 
		$content->server_domain, $content->server_port, 
		$content->user_path_string, $content->http_status_code;
}

1;
