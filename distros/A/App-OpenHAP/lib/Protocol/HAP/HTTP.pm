# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Protocol::HAP::HTTP;
our $VERSION = '0.1.0';

# Protocol::HAP::HTTP - one HTTP/1.1 codec, for both ends of a connection.
#
# The module is functions over strings. It opens no socket, holds no
# connection state, and never logs. A server calls parse_request and
# build_response; a client calls build_request and parse_response.
#
# message_complete is the framing. A stream socket gives a reader
# whatever arrived, which is not a message: a request can span two
# reads, and two requests can share one. A reader that parses each
# read as a whole message drops the second request and mangles the
# split one. The caller keeps a buffer and asks this function how much
# of it is a message.
#
# The module knows nothing about any protocol built on HTTP. A status
# code that belongs to one application, and the header defaults that
# one application wants, are arguments.

# The bound on a message that a caller does not set for itself. The
# value is generous for a request and small enough that an unpaired
# client cannot make a server hold megabytes.
use constant DEFAULT_MAX_SIZE => 65536;

# The status texts of the codes that RFC 9110 defines. A caller with a
# code of its own passes the text.
my %STATUS_TEXT = (
	200 => 'OK',
	201 => 'Created',
	204 => 'No Content',
	207 => 'Multi-Status',
	304 => 'Not Modified',
	400 => 'Bad Request',
	401 => 'Unauthorized',
	403 => 'Forbidden',
	404 => 'Not Found',
	405 => 'Method Not Allowed',
	408 => 'Request Timeout',
	413 => 'Content Too Large',
	500 => 'Internal Server Error',
	503 => 'Service Unavailable',
);

# message_complete($buffer, %args):
#	Report how many bytes at the front of $buffer form one whole
#	message.
#
#	%args:
#		max_size => $bytes	refuse a message larger than this
#
#	The function returns the length of the message, 0 when more
#	bytes are necessary, and undef when the message is over the
#	limit. A caller that gets undef closes the connection: the peer
#	is either broken or hostile, and no further byte can make the
#	message valid.
sub message_complete ( $buffer, %args )
{
	my $max_size = $args{max_size} // DEFAULT_MAX_SIZE;

	my $end = index $buffer, "\r\n\r\n";
	if ( $end < 0 ) {

		# The header block alone is already over the limit, so
		# no body can make it fit
		return if length($buffer) > $max_size;
		return 0;
	}

	my $head_length = $end + 4;
	my $head        = substr $buffer, 0, $end;

	# The trailing \r is part of the line terminator, and $ under /m
	# matches before the \n only. A class that omits it makes the
	# header match only when it is the last one in the block.
	my ($length) = $head =~ /^Content-Length:[ \t]*(\d+)[ \t\r]*$/mi;
	$length //= 0;

	my $total = $head_length + $length;
	return   if $total > $max_size;
	return 0 if length($buffer) < $total;

	return $total;
}

# parse_request($data):
#	Parse one request message. The function returns a hashref with
#	method, path, version, headers and body. Header names are
#	lowercase, because a peer chooses their case and a caller must
#	not.
#
#	The function returns undef when the request line is not a
#	request line.
sub parse_request ($data)
{
	my ( $head, $body ) = _split_message($data);
	my @lines = split /\r?\n/, $head;

	my $request_line = shift @lines // '';
	return
	    unless $request_line =~ m{^(\S+)[ \t]+(\S+)[ \t]+HTTP/(\d+\.\d+)$};

	return {
		method  => $1,
		path    => $2,
		version => $3,
		headers => _parse_headers( \@lines ),
		body    => $body,
	};
}

# parse_response($data):
#	Parse one response message. The function returns a hashref with
#	status, reason, version, headers and body, or undef when the
#	status line is not a status line.
sub parse_response ($data)
{
	my ( $head, $body ) = _split_message($data);
	my @lines = split /\r?\n/, $head;

	my $status_line = shift @lines // '';
	return
	    unless $status_line =~
	    m{^HTTP/(\d+\.\d+)[ \t]+(\d{3})(?:[ \t]+(.*))?$};

	return {
		version => $1,
		status  => $2,
		reason  => $3 // '',
		headers => _parse_headers( \@lines ),
		body    => $body,
	};
}

# build_request(%args):
#	Build one request message.
#
#	%args:
#		method  => $string	default GET
#		path    => $string	default /
#		version => $string	default 1.1
#		headers => \%headers	sent in sorted order
#		body    => $bytes
#
#	The function adds Content-Length when the caller gave a body
#	and no such header. A peer cannot frame a body without it.
sub build_request (%args)
{
	my $method  = $args{method}  // 'GET';
	my $path    = $args{path}    // '/';
	my $version = $args{version} // '1.1';
	my $body    = $args{body};
	my %headers = %{ $args{headers} // {} };

	$headers{'Content-Length'} = length $body
	    if defined $body && !_has_header( \%headers, 'content-length' );

	return
	      "$method $path HTTP/$version\r\n"
	    . _format_headers( \%headers ) . "\r\n"
	    . ( $body // '' );
}

# build_response(%args):
#	Build one response message.
#
#	%args:
#		status      => $code	default 200
#		status_text => $string	default from the code
#		version     => $string	default 1.1
#		headers     => \%headers
#		body        => $bytes
#
#	The function always adds Content-Length: a response with no
#	length and no close is a response that the peer waits out.
sub build_response (%args)
{
	my $status  = $args{status}      // 200;
	my $version = $args{version}     // '1.1';
	my $body    = $args{body}        // '';
	my $text    = $args{status_text} // status_text($status);
	my %headers = %{ $args{headers} // {} };

	$headers{'Content-Length'} = length $body
	    unless _has_header( \%headers, 'content-length' );

	return
	      "HTTP/$version $status $text\r\n"
	    . _format_headers( \%headers ) . "\r\n"
	    . $body;
}

# status_text($code):
#	Return the reason phrase of a status code. An unknown code
#	gives 'Unknown': an application with a code of its own passes
#	the text to build_response.
sub status_text ($code)
{
	return $STATUS_TEXT{$code} // 'Unknown';
}

# build_event($body):
#	Build one EVENT/1.0 notification message [HAP-HTTP §14]. The
#	message looks like a response, but its protocol name is EVENT,
#	so a controller can tell an unsolicited notification from the
#	answer to a request it sent.
sub build_event ($body)
{
	return
	      "EVENT/1.0 200 OK\r\n"
	    . "Content-Type: application/hap+json\r\n"
	    . 'Content-Length: '
	    . length($body)
	    . "\r\n\r\n"
	    . $body;
}

# _split_message($data):
#	Split a message into its header block and its body.
sub _split_message ($data)
{
	$data //= '';

	my ( $head, $body ) = split /\r?\n\r?\n/, $data, 2;

	return ( $head // '', $body // '' );
}

# _parse_headers($lines):
#	Turn the header lines into a hashref keyed by lowercase name.
#	A repeated header keeps its last value, as an assignment does.
sub _parse_headers ($lines)
{
	my %headers;
	for my $line (@$lines) {
		next unless $line =~ /^([^:]+):[ \t]*(.*?)[ \t]*$/;
		$headers{ lc $1 } = $2;
	}

	return \%headers;
}

# _has_header($headers, $name):
#	Report if the header set already holds a name, whatever case
#	the caller wrote it in.
sub _has_header ( $headers, $name )
{
	for my $key ( keys %$headers ) {
		return 1 if lc $key eq $name;
	}

	return 0;
}

# _format_headers($headers):
#	Format the headers, sorted. A stable order makes a response
#	comparable byte for byte, which a conformance test needs.
sub _format_headers ($headers)
{
	my $out = '';
	$out .= "$_: $headers->{$_}\r\n" for sort keys %$headers;

	return $out;
}

1;
