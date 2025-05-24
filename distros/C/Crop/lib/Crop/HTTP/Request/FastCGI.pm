package Crop::HTTP::Request::FastCGI;
use base qw/ Crop::HTTP::Request /;

=begin nd
Class: Crop::HTTP::Request::FastCGI
	HTTP request for Fast CGI protocol.
=cut

use v5.14;
use warnings;

use Crop::Server::FastCGI;

=begin nd
Constructor: new (%attr)
	Decompose a CGI request for separate attributes.

Parameters:
	Only one call exists
	>my $request = Crop::HTTPRequest::FastCGI->new(tik=now());

Returns:
	$self
=cut
sub new {
	my $class = shift;

	my $cgi = Crop::Server::FastCGI->instance->cgi;
	
	my %param = map +($_, scalar $cgi->param($_)), $cgi->param;

	# pack headers
	my @header = map +("$_:" . $cgi->http($_)), $cgi->http;
	my $headers;
	{
		local $" = "\n";
		$headers = "@header";
	}

	$class->SUPER::new(
		content_t => $cgi->content_type,
		cookie_in => scalar $cgi->cookie('session'),
		headers   => $headers,
		ip        => $cgi->http('X-Real-IP') // $cgi->remote_addr,
		method    => $cgi->request_method,
		param     => \%param,
		path      => $cgi->url(-absolute => 1),
		qstring   => $cgi->request_method eq 'GET' ? $cgi->query_string : undef,
		referer   => $cgi->referer,
		@_,
	);
}

1;
