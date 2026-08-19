#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Protocol::HAP::HTTP');

subtest 'parse a request' => sub {
	my $request = Protocol::HAP::HTTP::parse_request(
		    "GET /accessories HTTP/1.1\r\n"
		    . "Host: localhost\r\n"
		    . "Content-Type: application/hap+json\r\n"
		    . "\r\n" );

	is( $request->{method},  'GET',          'the method' );
	is( $request->{path},    '/accessories', 'the path' );
	is( $request->{version}, '1.1',          'the version' );
	is( $request->{headers}{host}, 'localhost', 'a header' );
	is( $request->{headers}{'content-type'},
		'application/hap+json', 'and another' );
	is( $request->{body}, '', 'an empty body' );

	# A peer chooses the case of a header name, so the reader must
	# not depend on it
	my $mixed = Protocol::HAP::HTTP::parse_request(
		"GET / HTTP/1.1\r\nCoNtEnT-tYpE: text/plain\r\n\r\n");
	is( $mixed->{headers}{'content-type'},
		'text/plain', 'a header name is lowercased' );

	my $post = Protocol::HAP::HTTP::parse_request(
		    "POST /characteristics HTTP/1.1\r\n"
		    . "Content-Length: 13\r\n"
		    . "\r\n"
		    . '{"test":true}' );
	is( $post->{method}, 'POST',          'a POST method' );
	is( $post->{body},   '{"test":true}', 'and its body' );

	is( Protocol::HAP::HTTP::parse_request("not a request line\r\n\r\n"),
		undef, 'a line that is not a request line' );
	is( Protocol::HAP::HTTP::parse_request(''), undef, 'an empty message' );
};

subtest 'parse a response' => sub {
	my $response = Protocol::HAP::HTTP::parse_response(
		    "HTTP/1.1 207 Multi-Status\r\n"
		    . "Content-Type: application/hap+json\r\n"
		    . "Content-Length: 22\r\n"
		    . "\r\n"
		    . '{"characteristics":[]}' );

	is( $response->{status},  207,             'the status' );
	is( $response->{reason},  'Multi-Status',  'the reason phrase' );
	is( $response->{version}, '1.1',           'the version' );
	is( $response->{body}, '{"characteristics":[]}', 'the body' );
	is( $response->{headers}{'content-length'}, 22, 'a header' );

	my $bare = Protocol::HAP::HTTP::parse_response("HTTP/1.1 204\r\n\r\n");
	is( $bare->{status}, 204, 'a status line with no reason phrase' );
	is( $bare->{reason}, '',  'and an empty reason' );

	is( Protocol::HAP::HTTP::parse_response("garbage\r\n\r\n"),
		undef, 'a line that is not a status line' );
};

subtest 'build a request' => sub {
	my $request = Protocol::HAP::HTTP::build_request(
		method  => 'POST',
		path    => '/pair-setup',
		headers => { 'Content-Type' => 'application/pairing+tlv8' },
		body    => 'tlvbytes',
	);

	like( $request, qr{^POST /pair-setup HTTP/1\.1\r\n}, 'the request line' );
	like( $request, qr{\r\nContent-Length: 8\r\n},
		'the length of the body is declared' );
	like( $request, qr{\r\n\r\ntlvbytes$}, 'and the body follows' );

	my $bare = Protocol::HAP::HTTP::build_request();
	like( $bare, qr{^GET / HTTP/1\.1\r\n}, 'the defaults are GET and /' );
	unlike( $bare, qr{Content-Length}, 'and a request with no body has none' );

	# A caller that set the header itself keeps its value
	my $own = Protocol::HAP::HTTP::build_request(
		body    => 'xxxx',
		headers => { 'content-length' => 4 },
	);
	my @lengths = $own =~ /content-length/gi;
	is( scalar @lengths, 1, 'the length is declared once' );
};

subtest 'build a response' => sub {
	my $response = Protocol::HAP::HTTP::build_response(
		status  => 200,
		headers => { 'Content-Type' => 'application/hap+json' },
		body    => '{"status":"ok"}',
	);

	like( $response, qr{^HTTP/1\.1 200 OK\r\n},        'the status line' );
	like( $response, qr{\r\nContent-Length: 15\r\n},   'the length' );
	like( $response, qr{\r\n\r\n\{"status":"ok"\}$},   'the body' );

	my $empty = Protocol::HAP::HTTP::build_response( status => 204 );
	like( $empty, qr{^HTTP/1\.1 204 No Content\r\n}, 'a known reason phrase' );
	like( $empty, qr{Content-Length: 0},
		'a response with no body still declares a length' );

	my $custom = Protocol::HAP::HTTP::build_response(
		status      => 470,
		status_text => 'Connection Authorization Required',
	);
	like( $custom, qr{^HTTP/1\.1 470 Connection Authorization Required\r\n},
		'a caller can name a reason the codec does not know' );
	like( Protocol::HAP::HTTP::build_response( status => 470 ),
		qr{470 Unknown}, 'and an unknown code alone reads as Unknown' );

	# The header order is stable, so a conformance test can compare
	# a response byte for byte
	my %args = (
		status  => 200,
		headers => { Zulu => 1, Alpha => 2, Mike => 3 },
	);
	is( Protocol::HAP::HTTP::build_response(%args),
		Protocol::HAP::HTTP::build_response(%args),
		'the same arguments give the same bytes' );
	like(
		Protocol::HAP::HTTP::build_response(%args),
		qr{Alpha: 2\r\nContent-Length: 0\r\nMike: 3\r\nZulu: 1},
		'the headers are sorted'
	);
};

subtest 'status_text' => sub {
	is( Protocol::HAP::HTTP::status_text(200), 'OK', 'the text of 200' );
	is( Protocol::HAP::HTTP::status_text(404), 'Not Found', 'the text of 404' );
	is( Protocol::HAP::HTTP::status_text(413),
		'Content Too Large', 'the text of 413' );
	is( Protocol::HAP::HTTP::status_text(999), 'Unknown', 'an unknown code' );
};

# A stream socket gives a reader whatever arrived, which is not a
# message. Everything below is the framing that a server needs to not
# drop or mangle a request.
subtest 'framing: a message split across reads' => sub {
	my $whole =
	      "POST /characteristics HTTP/1.1\r\n"
	    . "Content-Length: 13\r\n"
	    . "\r\n"
	    . '{"test":true}';

	# One byte at a time. Only the last one completes the message.
	my $buffer = '';
	my @complete;
	for my $byte ( split //, $whole ) {
		$buffer .= $byte;
		push @complete, Protocol::HAP::HTTP::message_complete($buffer);
	}

	is( scalar( grep { $_ } @complete ), 1, 'the message completes once' );
	is( $complete[-1], length($whole), 'at exactly its own length' );

	# Content-Length is found wherever it sits in the block. A
	# pattern anchored with $ under /m stops at the \r of the line
	# terminator, so it would match only the last header and every
	# real response would frame short.
	my $middle =
	      "HTTP/1.1 200 OK\r\n"
	    . "Connection: keep-alive\r\n"
	    . "Content-Length: 5\r\n"
	    . "Content-Type: text/plain\r\n"
	    . "\r\n" . 'hello';
	is( Protocol::HAP::HTTP::message_complete($middle),
		length($middle), 'a header that is not the last one is read' );

	# A message whose headers arrived but whose body has not
	my $headers_only = substr $whole, 0, index( $whole, "\r\n\r\n" ) + 4;
	is( Protocol::HAP::HTTP::message_complete($headers_only),
		0, 'headers with a declared body are not a whole message' );

	my $parsed = Protocol::HAP::HTTP::parse_request($whole);
	is( $parsed->{body}, '{"test":true}', 'and the whole one parses' );
};

subtest 'framing: two messages in one read' => sub {
	my $first =
	    "GET /accessories HTTP/1.1\r\nHost: a\r\n\r\n";
	my $second =
	      "PUT /characteristics HTTP/1.1\r\n"
	    . "Content-Length: 2\r\n"
	    . "\r\n" . '{}';

	my $buffer = $first . $second;

	my $length = Protocol::HAP::HTTP::message_complete($buffer);
	is( $length, length($first), 'the first message ends where it ends' );

	my $one = substr $buffer, 0, $length, '';
	is( Protocol::HAP::HTTP::parse_request($one)->{path},
		'/accessories', 'and it parses' );

	$length = Protocol::HAP::HTTP::message_complete($buffer);
	is( $length, length($second), 'the second message follows' );

	my $two = substr $buffer, 0, $length, '';
	is( Protocol::HAP::HTTP::parse_request($two)->{path},
		'/characteristics', 'and it parses too' );
	is( $buffer, '', 'nothing is left over' );

	is( Protocol::HAP::HTTP::message_complete($buffer),
		0, 'an empty buffer holds no message' );
};

subtest 'framing: a message over the limit' => sub {
	my $body    = 'x' x 200;
	my $request =
	      "POST / HTTP/1.1\r\n"
	    . 'Content-Length: '
	    . length($body)
	    . "\r\n\r\n"
	    . $body;

	ok( Protocol::HAP::HTTP::message_complete( $request, max_size => 1000 ),
		'inside the limit it completes' );

	is( Protocol::HAP::HTTP::message_complete( $request, max_size => 100 ),
		undef, 'over the limit it is refused' );

	# The refusal comes from the declared length, before the body
	# arrives. A server must not first accept the bytes it is about
	# to refuse.
	my $head = substr $request, 0, index( $request, "\r\n\r\n" ) + 4;
	is( Protocol::HAP::HTTP::message_complete( $head, max_size => 100 ),
		undef, 'the declared length alone is enough to refuse' );

	# A header block with no end, over the limit, is refused too:
	# no further byte can make it valid
	is( Protocol::HAP::HTTP::message_complete( 'x' x 200, max_size => 100 ),
		undef, 'an endless header block is refused' );
	is( Protocol::HAP::HTTP::message_complete( 'x' x 50, max_size => 100 ),
		0, 'but a short one is only incomplete' );
};

subtest 'build_event builds an EVENT/1.0 message [HAP-HTTP §14]' => sub {
	my $body  = '{"characteristics":[]}';
	my $event = Protocol::HAP::HTTP::build_event($body);

	like( $event, qr{^EVENT/1\.0 200 OK\r\n},
		'the protocol name is EVENT, not HTTP' );
	like( $event, qr{Content-Type: application/hap\+json\r\n},
		'the content type is application/hap+json' );
	like( $event, qr{Content-Length: 22\r\n},
		'the length frames the body' );
	like( $event, qr{\r\n\r\n\Q$body\E$}, 'the body ends the message' );

	# An event is not a response: parse_response must refuse it, so
	# a controller can tell the two apart
	is( Protocol::HAP::HTTP::parse_response($event),
		undef, 'parse_response refuses an EVENT message' );
};

done_testing();
