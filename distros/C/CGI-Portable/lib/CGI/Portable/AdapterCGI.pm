=head1 NAME

CGI::Portable::AdapterCGI - Run under CGI, Apache::Registry, cmd line

=cut

######################################################################

package CGI::Portable::AdapterCGI;
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

	Apache (when running under mod_perl only)

=head2 Nonstandard Modules

	CGI::Portable 0.50

=head1 SYNOPSIS

=head2 Content of thin shell "startup_cgi.pl" for CGI or Apache::Registry env:

	#!/usr/bin/perl
	use strict;
	use warnings;

	require CGI::Portable;
	my $globals = CGI::Portable->new();

	use Cwd;
	$globals->file_path_root( cwd() );  # let us default to current working directory
	$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

	$globals->set_prefs( 'config.pl' );
	$globals->current_user_path_level( 1 );

	require CGI::Portable::AdapterCGI;
	my $io = CGI::Portable::AdapterCGI->new();

	$io->fetch_user_input( $globals );
	$globals->call_component( 'DemoAardvark' );
	$io->send_user_output( $globals );

	1;

=head1 DESCRIPTION

This Perl 5 object class is an adapter for CGI::Portable that takes care of the 
details for gathering user input and sending user output in a CGI environment.  
Perl scripts running under the CGI protocol communicate with the HTTP server 
through the global symbols named [%ENV, STDIN, STDOUT]; they read from the first 
two and write to the third one.  

The Perl module named Apache::Registry can also simulate a CGI environment while
running under mod_perl, with a few caveats.  CGI::Portable::AdapterCGI can sense
when it is running under Apache::Registry by checking $ENV{'GATEWAY_INTERFACE'}
and adjust its behaviour as appropriate.  Specifically, the output HTTP headers
are sent using an Apache method rather than through STDOUT.

If this module does not see a valid $ENV{'REQUEST_METHOD'} value then it will 
assume the script is being debugged on the command line and will either use 
existing shell arguments to simulate an HTTP request or it will prompt the user 
interactively for request details.  The response is sent using STDOUT as usual.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new()

This function creates a new CGI::Portable::AdapterCGI object and returns it.  
The new object has no properties, but only methods.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	return( $self );
}

######################################################################

=head2 fetch_user_input( GLOBALS )

This method takes a CGI::Portable object as its first argument, GLOBALS, and 
feeds it all of the HTTP request and user input details that it can gather.  
The user_path() is always initialized from $ENV{'PATH_INFO'} by this method; 
if you want it to be from a query param then you can update it yourself later.

=cut

######################################################################

sub fetch_user_input {
	my ($self, $globals) = @_;

	$globals->server_ip( '127.0.0.1' );  # there is no ENV for this, is there?
	$globals->server_domain( $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || 
		'localhost' );
	$globals->server_port( $ENV{'SERVER_PORT'} || 80 );
	$globals->client_ip( $ENV{'REMOTE_ADDR'} || '127.0.0.1' );
	$globals->client_domain( $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'} || 
		'localhost' );
	$globals->client_port( $ENV{'REMOTE_PORT'} );

	my $host = $globals->server_domain();
	my $port = $globals->server_port();
	$globals->url_base( 'http://'.$host.($port != 80 ? ":$port" : '').
		$self->_uri_unescape( $ENV{'SCRIPT_NAME'} ) );

	$globals->request_method( $ENV{'REQUEST_METHOD'} || 'GET' );
	$globals->request_uri( $ENV{'REQUEST_URI'} || '/' );
	$globals->request_protocol( $ENV{'SERVER_PROTOCOL'} || 'HTTP/1.0' );

	$globals->referer( $self->_uri_unescape( $ENV{'HTTP_REFERER'} ) );
	$globals->user_agent( $ENV{'HTTP_USER_AGENT'} );

	my ($path_info, $query, $post, $oversize, $cookies);

	if( $ENV{'REQUEST_METHOD'} =~ /^(GET|HEAD|POST)$/ ) {
		$path_info = $self->_uri_unescape( $ENV{'PATH_INFO'} );

		$query = $ENV{'QUERY_STRING'};
		$query ||= $ENV{'REDIRECT_QUERY_STRING'};

		if( $ENV{'CONTENT_LENGTH'} > 0 ) {
			read( STDIN, $post, $ENV{'CONTENT_LENGTH'} );
			chomp( $post );
		}

		$cookies = $ENV{'HTTP_COOKIE'} || $ENV{'COOKIE'};

	} elsif( $ARGV[1] ) {  # allow caller to save $ARGV[0] for the http_host
		$path_info = $ARGV[1];
		$query = $ARGV[2];
		$post = $ARGV[3];
		$cookies = $ARGV[4];

	} else {
		print STDERR "offline mode: enter path_info on standard input\n";
		print STDERR "it must be all on one line\n";
		$path_info = <STDIN>;
		chomp( $path_info );

		print STDERR "offline mode: enter query_string on standard input\n";
		print STDERR "it must be query-escaped and all on one line\n";
		$query = <STDIN>;
		chomp( $query );

		print STDERR "offline mode: enter post_string on standard input\n";
		print STDERR "it must be query-escaped and all on one line\n";
		$post = <STDIN>;
		chomp( $post );

		print STDERR "offline mode: enter cookies_string on standard input\n";
		print STDERR "they must be cookie-escaped and all on one line\n";
		$cookies = <STDIN>;
		chomp( $cookies );
	}

	$globals->user_path( $path_info );
	$globals->user_query( $query );
	$globals->user_post( $post );
	$globals->user_cookies( $cookies );
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

=head2 send_user_output( GLOBALS )

This method takes a CGI::Portable object as its first argument, GLOBALS, and 
sends to the user as much of the HTTP response and user output details that it 
can get from the object.

=head2 send_quick_html_response( CONTENT )

This method takes a string containing an HTML document as its first argument, 
CONTENT, and sends an http response appropriate for an HTML document which 
includes CONTENT as the http body.

=head2 send_quick_redirect_response( URL )

This method takes a string containing an url as its first argument, URL, and 
sends an http redirection header to send the client browser to that url.

=cut

######################################################################

sub send_user_output {
	my ($self, $globals) = @_;
	my $status = $globals->http_status_code() || '200 OK';
	my $target = $globals->http_window_target();
	my $type = $globals->http_content_type() || 'text/html';
	my $url = $globals->http_redirect_url();
	my @cookies = $globals->get_http_cookies();
	my %misc = $globals->get_http_headers();
	my $content = $globals->http_body() || $globals->page_as_string();
	my $binary = $globals->http_body_is_binary();
	$self->_send_output( $status, $type, $url, $target, $content, $binary, 
		\@cookies, \%misc );
}

sub send_quick_html_response {
	my ($self, $content) = @_;
	$self->_send_output( '200 OK', 'text/html', undef, undef, $content );
}

sub send_quick_redirect_response {
	my ($self, $url) = @_;
	$self->_send_output( '301 Moved', undef, $url );
}

# _send_output( STATUS, TYPE, [URL, [TARGET[, CONTENT[, IS_BINARY[, 
#    COOKIES[, MISC]]]]]] )
# This private method is used to implement all the send_*() methods above, 
# and works under both mod_perl and cgi.  It currently does not support NPH 
# responses but that should be added in the future.

sub _send_output {
	my ($self, $status, $type, $url, $target, $content, $is_binary, 
		$cook, $misc) = @_;
	ref($cook) eq 'ARRAY' or $cook = [];
	ref($misc) eq 'HASH' or $misc = {};

	my @header = ("Status: $status");
	$target and push( @header, "Window-Target: $target" );
	@{$cook} and push( @header, map { "Set-Cookie: $_" } @{$cook} );
	push( @header, $url ? "Location: $url" : "Content-Type: $type" );
	%{$misc} and push( @header, map { "$_: $misc->{$_}" } sort keys %{$misc} );
	my $endl = "\015\012";  # cr + lf
	my $header = join( $endl, @header ).$endl.$endl;

	if( $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/ ) {
		require Apache;
		$| = 1;
		my $req = Apache->request();
		$req->send_cgi_header( $header );

	} else {
		print STDOUT $header;
	}

	$is_binary and binmode( STDOUT );
	print STDOUT $content;
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

perl(1), CGI::Portable, Apache.

=cut
