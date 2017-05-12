=head1 NAME

CGI::Portable::AdapterSocket - Run under IO::Socket-based Perl server

=cut

######################################################################

package CGI::Portable::AdapterSocket;
require 5.004;

# Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.50';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	IO::Socket  -- IO::Socket::INET built in

=head2 Nonstandard Modules

	CGI::Portable 0.50

=cut

######################################################################

use IO::Socket;

######################################################################

=head1 SYNOPSIS

=head2 Content of thin shell "startup_socket.pl" for IO::Socket::INET:

	#!/usr/bin/perl
	use strict;
	use warnings;

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

=head1 DESCRIPTION

This Perl 5 object class is an adapter for CGI::Portable that takes care of the 
details for gathering user input and sending user output when this Perl script 
is the HTTP server itself, and IO::Socket (IO::Socket::INET) is being used for 
networking with the HTTP client.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new()

This function creates a new CGI::Portable::AdapterSocket object and returns it.  
The new object has no properties, but only methods.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	return( $self );
}

######################################################################

=head2 fetch_user_input( GLOBALS, CLIENT )

This method takes a CGI::Portable object as its first argument, GLOBALS, and 
feeds it all of the HTTP request and user input details that it can gather.  
The second argument, CLIENT, is an IO::Socket::INET object which is the client 
we will be getting our input from.
The user_path() is always initialized from the requested uri by this method; 
if you want it to be from a query param then you can update it yourself later.  
For debugging purposes, this method returns two strings containing the 
un-parsed HTTP request headers and body respectively, should you want to inspect 
them for yourself later.

=cut

######################################################################

sub fetch_user_input {
	my ($self, $globals, $client) = @_;

	$globals->server_ip( $client->sockhost() || '127.0.0.1' );  # number
	$globals->server_domain( $client->sockaddr() || 'localhost' );  # domain
	$globals->server_port( $client->sockport() || 80 );
	$globals->client_ip( $client->peerhost() || '127.0.0.1' );  # number
	$globals->client_domain( $client->peeraddr() || $client->peerhost() || 
		'localhost' );  # domain
	$globals->client_port( $client->peerport() );

	my $host = $globals->server_domain();
	my $port = $globals->server_port();
	$globals->url_base( 'http://'.$host.($port != 80 ? ":$port" : '') );

	my $endl = "\015\012";  # cr + lf
	local $\ = $endl.$endl;
	local $/ = $endl.$endl;
	my $raw_http_headers = <$client>;
	my ($request, @headers_in) = grep( /\w/, split( $endl, $raw_http_headers ) );

	my ($method, $uri, $protocol) = grep( /\S/, split( /\s/, $request ) );
	$globals->request_method( $method || 'GET' );
	$globals->request_uri( $uri || '/' );
	$globals->request_protocol( $protocol || 'HTTP/1.0' );
	my ($path, $query) = split( /\?/, $uri );
	$globals->user_path( $self->_uri_unescape( $path ) );
	$globals->user_query( $query );

	my $content_length = 0;
	foreach my $header_in (@headers_in) {
		my ($key, $value) = split( ": ", $header_in );
		$key = lc( $key );
		$key eq 'host' and do {
			my ($hdomain, $hport) = split( ":", $value );
			$hdomain and $globals->server_domain( $hdomain );
			$hport and $globals->server_port( $hport );
		} and next;
		$key eq 'referer' and 
			$globals->referer( $self->_uri_unescape( $value ) ) and next;
		$key eq 'user-agent' and $globals->user_agent( $value ) and next;
		$key eq 'cookie' and $globals->user_cookies( $value ) and next;
		$key =~ /length/ and $content_length = $value and next;
	}

	my $raw_http_body = '';
	if( $content_length > 0 ) {
		my $raw_http_body = '';
		read( $client, $raw_http_body, $content_length );
		chomp( $raw_http_body );
		$globals->user_post( $raw_http_body );
	}

	return( $raw_http_headers, $raw_http_body );  # for debugging
}

# _uri_unescape( STRING )
# This private method takes a string in the argument STRING, and returns 
# an uri-unescaped version of it.

sub _uri_unescape {
	my ($self, $str) = @_;
	$str =~ tr/+/ /;
	$str =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return( $str );
}

######################################################################

=head2 send_user_output( GLOBALS, CLIENT )

This method takes a CGI::Portable object as its first argument, GLOBALS, and 
sends to the user as much of the HTTP response and user output details that it 
can get from the object.
The second argument, CLIENT, is an IO::Socket::INET object which is the client 
we will be sending our output to.

=head2 send_quick_html_response( CONTENT, CLIENT )

This method takes a string containing an HTML document as its first argument, 
CONTENT, and sends an http response appropriate for an HTML document which 
includes CONTENT as the http body.
The second argument, CLIENT, is an IO::Socket::INET object which is the client 
we will be sending our output to.

=head2 send_quick_redirect_response( URL, CLIENT )

This method takes a string containing an url as its first argument, URL, and 
sends an http redirection header to send the client browser to that url.
The second argument, CLIENT, is an IO::Socket::INET object which is the client 
we will be sending our output to.

=cut

######################################################################

sub send_user_output {
	my ($self, $globals, $client) = @_;
	my $status = $globals->http_status_code() || '200 OK';
	my $target = $globals->http_window_target();
	my $type = $globals->http_content_type() || 'text/html';
	my $url = $globals->http_redirect_url();
	my @cookies = $globals->get_http_cookies();
	my %misc = $globals->get_http_headers();
	my $content = $globals->http_body() || $globals->page_as_string();
	my $binary = $globals->http_body_is_binary();
	$self->_send_output( $client, $status, $type, $url, $target, $content, 
		$binary, \@cookies, \%misc );
}

sub send_quick_html_response {
	my ($self, $content, $client) = @_;
	$self->_send_output( $client, '200 OK', 'text/html', undef, undef, $content );
}

sub send_quick_redirect_response {
	my ($self, $url, $client) = @_;
	$self->_send_output( $client, '301 Moved', undef, $url );
}

# _send_output( CLIENT, STATUS, TYPE, [URL, [TARGET[, CONTENT[, IS_BINARY[, 
#	COOKIES[, MISC]]]]]] )
# This private method is used to implement all the send_*() methods above, 
# and works under both mod_perl and cgi.  It currently does not support NPH 
# responses but that should be added in the future.

sub _send_output {
	my ($self, $client, $status, $type, $url, $target, $content, $is_binary, 
		$cook, $misc) = @_;
	ref($cook) eq 'ARRAY' or $cook = [];
	ref($misc) eq 'HASH' or $misc = {};

	my @header = ("Status: $status");
	$target and push( @header, "Window-Target: $target" );
	@{$cook} and push( @header, map { "Set-Cookie: $_" } @{$cook} );
	push( @header, $url ? "Location: $url" : "Content-Type: $type" );
	%{$misc} and push( @header, map { "$_: $misc->{$_}" } sort keys %{$misc} );
	unshift( @header, "HTTP/1.0 $status" );

	my $endl = "\015\012";  # cr + lf
	my $header = join( $endl, @header ).$endl.$endl;

	$client->autoflush(1);
	print $client $header;
	$is_binary and binmode( $client );
	print $client $content;
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), CGI::Portable, IO::Socket, IO::Socket::INET.

=cut
