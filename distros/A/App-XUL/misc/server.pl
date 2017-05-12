#!/usr/bin/perl
package main;

use strict;
use warnings;
use Socket;
use IO::Socket;
use LWP::Simple qw(get);
use URI::Escape qw(uri_escape);
use JSON qw(to_json from_json);
use Data::Dumper;

# get commandline arguments
my ($ModulesPath, $Port) = @ARGV;

# load user-defined event handlers
unshift @INC, $ModulesPath;
eval('use Eventhandlers;');
my $Eventhandlers = Eventhandlers::get();

# start server
my $Server = 
	new IO::Socket::INET(
		Proto => 'tcp',
		LocalPort => $Port,
		Listen => SOMAXCONN,
		Reuse => 1,
	)
	or die "Unable to create server socket: $!";

# await requests and handle them as they arrive
while (my $client = $Server->accept())
{
	$client->autoflush(1);
	my %request = ();
	my %data;
	{
		# read request
		local $/ = Socket::CRLF;
		while (<$client>) {
			chomp; # Main http request
			if (/\s*(\w+)\s*([^\s]+)\s*HTTP\/(\d.\d)/) {
				$request{METHOD} = uc $1;
				$request{URL} = $2;
				$request{HTTP_VERSION} = $3;
			} # Standard headers
			elsif (/:/) {
				(my $type, my $val) = split /:/, $_, 2;
				$type =~ s/^\s+//;
				foreach ($type, $val) {
					s/^\s+//;
					s/\s+$//;
				}
				$request{lc $type} = $val;
			} # POST data
			elsif (/^$/) {
				read($client, $request{CONTENT}, $request{'content-length'})
					if defined $request{'content-length'};
				last;
			}
		}
	}
	
	# sort out method
	if ($request{'METHOD'} eq 'GET') {
		if ($request{'URL'} =~ /(.*)\?(.*)/) {
			$request{'URL'} = $1;
			$request{'CONTENT'} = $2;
			%data = parse_params($request{'CONTENT'});
		} else {
			%data = ();
		}
		$data{"_method"} = "GET";
	} elsif ($request{'METHOD'} eq 'POST') {
		%data = parse_params($request{'CONTENT'});
		$data{"_method"} = "POST";
	} else {
		$data{"_method"} = "ERROR";
	}
		
	# analyse request and create answer
	my $info = from_json($data{'data'});
	
	#print STDERR Dumper($info);
	
	my $quit = 0;
	$quit = 1 if exists $info->{'event'} && $info->{'event'} eq 'quit';

	my $answer;
	if (exists $info->{'id'} && $info->{'event'}) {
		my $eventhandler_id = $info->{'id'}.':'.$info->{'event'};
		$answer = $Eventhandlers->{$eventhandler_id}->()
			if exists $Eventhandlers->{$eventhandler_id};
	}
	$answer = {'action' => "none"} unless ref $answer eq 'HASH';
	
	#print STDERR "sending answer ".Dumper($answer);
	
	# send answer
	print $client "HTTP/1.0 200 Ok", Socket::CRLF;
	#print $client "Content-type: application/json", Socket::CRLF;
	print $client "Content-type: text/html", Socket::CRLF;
	print $client Socket::CRLF;
	print $client ((($answer && to_json($answer)) || '{"action":"none"}'), Socket::CRLF);

	# close connection and loop
	close $client;
	
	exit if $quit;
}

################################################################################

# this pushes some action to the client to be performed and
# returns after the client answers
sub push
{
	my ($action) = @_;
	my $url = 'http://localhost:3001/?data='.uri_escape(to_json($action));
	my $content = get($url);
	#print STDERR "sending async ".Dumper($action)."\nurl = $url\n";
	#print STDERR "-> $content\n\n";
	my $info = from_json($content);
	return $info->{'content'};
}

# this binds a coderef to an id+event name to be triggered
# by the client (XUL app)
sub bind
{
	my ($id, $event, $coderef) = @_;
	$Eventhandlers->{$id.':'.$event} = $coderef;
}

sub parse_params
{
	my $data = $_[0];
	my %data;
	foreach (split /&/, $data) {
		my ($key, $val) = split /=/;
		$val =~ s/\+/ /g;
		$val =~ s/%(..)/chr(hex($1))/eg;
		$data{$key} = $val;
	}
	return %data;
}

1;
