#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( encode_json decode_json );
use API::Docker;
use Test::API::Docker::FakeTransport;

# API::Docker::Role::HTTP sits below _request as far as Test::API::Docker::Mock
# is concerned -- the mock replaces _request wholesale, so request-line
# assembly, header sanitising, chunked reading, status handling and the
# >=400 croak path are exercised by nothing but use_ok in t/basic.t.
#
# Nothing here opens a real socket or reaches a daemon: the socket-facing
# methods (_read_response, _read_chunked) are driven directly over a tied
# filehandle, and _request itself is driven through a subclass that fakes the
# socket instead of connecting one. So this file needs no is_live()/can_write()
# gating -- it is unconditionally safe with no Docker installed.

# ---------------------------------------------------------------------------
# A tied filehandle serving a fixed string, with a step: 0 hands over
# everything that is left in one call, a positive N hands over at most N bytes
# per call, so "a chunk arriving in several reads" is a real multi-call
# scenario for _read_chunked's inner while loop rather than one read that
# happens to satisfy the whole request.
#
# This used to be an in-memory scalar filehandle (open $fh, '<', \$str) for
# everything but the multi-read case. It cannot be one any more: since karr k60
# the transport reads with sysread, and sysread on a scalar filehandle fails
# outright -- measured, it returns undef with EBADF, because such a handle has
# no file descriptor (fileno is -1). A tied handle is the shape that works for
# both, and it also makes the step explicit rather than inherited from
# PerlIO::scalar's own behaviour.
package Test::RoleHTTP::PartialReader;

sub TIEHANDLE {
  my ($class, $data, $step) = @_;
  return bless { buf => $data, pos => 0, step => defined $step ? $step : 0 },
    $class;
}

sub READ {
  my $self   = $_[0];
  my $len    = $_[2];
  my $offset = $_[3] || 0;
  my $avail  = length($self->{buf}) - $self->{pos};
  return 0 if $avail <= 0;
  my $n = $len;
  $n = $self->{step} if $self->{step} && $n > $self->{step};
  $n = $avail if $n > $avail;
  my $chunk = substr($self->{buf}, $self->{pos}, $n);
  if ($offset) {
    substr($_[1], $offset, $n) = $chunk;
  }
  else {
    $_[1] = $chunk;
  }
  $self->{pos} += $n;
  return $n;
}

sub CLOSE { 1 }

package main;

# A handle over $data. Anonymous, so several can be alive at once and none
# needs untying.
sub string_handle {
  my ($data, $step) = @_;
  my $fh = \do { no warnings 'once'; local *HANDLE };
  tie *$fh, 'Test::RoleHTTP::PartialReader', $data, $step;
  return $fh;
}

# What the transport has read off a handle but not yet consumed. Since karr k60
# the read-ahead past a header block lands here instead of in PerlIO's own
# buffer, which is what makes "these bytes were not swallowed" answerable.
sub unconsumed {
  my ($client, $fh) = @_;
  return ${ $client->_read_buffer($fh) };
}

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

# ---------------------------------------------------------------------------
subtest '_read_response: status line parsing' => sub {
  my $fh = string_handle("HTTP/1.1 204 No Content\r\n\r\n");
  my $resp = $client->_read_response($fh);
  is $resp->[0], 204, 'status code';
  is $resp->[1], 'No Content', 'status text, including the embedded space';
};

subtest '_read_response: header collection' => sub {
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Content-Type: application/json\r\n"
    . "X-Mixed-CASE:   value with spaces  \r\n"
    . "Content-Length: 2\r\n"
    . "\r\n"
    . "{}";
  my $fh = string_handle($raw);
  my $resp = $client->_read_response($fh);
  my $headers = $resp->[2];

  is $headers->{'content-type'}, 'application/json',
    'an already-lowercase key is kept';
  is $headers->{'x-mixed-case'}, 'value with spaces  ',
    'a mixed-case key is lowercased; leading space after the colon is '
    . 'trimmed, the rest of the value is kept verbatim (trailing spaces too)';
  is $headers->{'content-length'}, '2', 'colon splits key from value';
  is $resp->[3], '{}', 'body still decoded via content-length';
};

subtest '_read_response: chunked body' => sub {
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Transfer-Encoding: chunked\r\n"
    . "\r\n"
    . "5\r\nhello\r\n"
    . "6\r\n world\r\n"
    . "0\r\n\r\n";
  my $fh = string_handle($raw);
  my $resp = $client->_read_response($fh);
  is $resp->[3], 'hello world', 'chunks concatenated, chunk framing stripped';
};

subtest '_read_response: content-length body' => sub {
  # Embedded CRLF and a NUL byte prove this is a byte-exact length read, not
  # a line-oriented one.
  my $body = "line1\r\nline2\x00tail";
  my $raw = 'HTTP/1.1 200 OK' . "\r\n"
    . 'Content-Length: ' . length($body) . "\r\n"
    . "\r\n"
    . $body;
  my $fh = string_handle($raw);
  my $resp = $client->_read_response($fh);
  is $resp->[3], $body,
    'exactly content-length bytes read, embedded CRLF/NUL preserved';
};

subtest '_read_response: read-to-EOF fallback' => sub {
  # Neither Transfer-Encoding nor Content-Length -- the pre-HTTP/1.1-ish
  # case where the body is "whatever remains until the connection closes".
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Connection: close\r\n"
    . "\r\n"
    . "no length header, read until eof";
  my $fh = string_handle($raw);
  my $resp = $client->_read_response($fh);
  is $resp->[3], 'no length header, read until eof',
    'falls back to slurping the rest of the socket';
};

# ---------------------------------------------------------------------------
# HTTP field values are case-insensitive (RFC 9110 section 5.6.2). A daemon or
# a proxy in front of it may write Transfer-Encoding in any case; the value is
# compared with lc() so that a body announced as chunked is dechunked whatever
# the spelling. Before this, a value that was not exactly 'chunked' fell
# through to the close-delimited branch and the raw chunk framing came back as
# the body.
subtest '_read_response: Transfer-Encoding is matched case-insensitively'
  => sub {
  for my $spelling (qw( Chunked CHUNKED chUNKed )) {
    my $raw = "HTTP/1.1 200 OK\r\n"
      . "Transfer-Encoding: $spelling\r\n"
      . "\r\n"
      . "5\r\nhello\r\n6\r\n world\r\n0\r\n\r\n";
    my $resp = $client->_read_response(string_handle($raw));
    is $resp->[3], 'hello world',
      "Transfer-Encoding: $spelling is dechunked, not returned as framing";
  }
};

subtest 'the streaming reader dechunks a case-varied Transfer-Encoding too'
  => sub {
  my @got;
  my $handler = $client->_stream_handler('GET /v1.41/events', 'on_event',
    sub { push @got, $_[0] }, 0);
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Transfer-Encoding: Chunked\r\n"
    . "\r\n"
    . qq(11\r\n{"status":"one"}\n\r\n)
    . qq(11\r\n{"status":"two"}\n\r\n)
    . "0\r\n\r\n";
  $client->_read_streaming_response(string_handle($raw), 'GET', $handler, {});
  is_deeply [ map { ref $_ eq 'HASH' ? $_->{status} : $_ } @got ],
    [qw( one two )],
    'exactly the two events, not the chunk framing decoded line by line';
};

# ---------------------------------------------------------------------------
# A 1xx informational response (100 Continue, 103 Early Hints, ...) is a whole
# head with no body, sent before the real response (RFC 9110 section 15.2). It
# is read and discarded so the reader continues with the real response rather
# than taking the 1xx status and reading the real response as its body.
subtest '_read_response: a 1xx informational response is skipped' => sub {
  my $raw = "HTTP/1.1 100 Continue\r\n\r\n"
    . "HTTP/1.1 200 OK\r\n"
    . "Content-Length: 2\r\n\r\n"
    . "{}";
  my $resp = $client->_read_response(string_handle($raw));
  is $resp->[0], 200, 'the real status is returned, not the 100';
  is $resp->[1], 'OK', 'and its reason';
  is $resp->[3], '{}', 'and the real body, not the second response as bytes';
};

subtest '_read_response: several stacked 1xx heads are all skipped' => sub {
  my $raw = "HTTP/1.1 100 Continue\r\n\r\n"
    . "HTTP/1.1 103 Early Hints\r\nLink: </x>; rel=preload\r\n\r\n"
    . "HTTP/1.1 204 No Content\r\n\r\n";
  my $resp = $client->_read_response(string_handle($raw));
  is $resp->[0], 204, 'the first non-1xx status wins';
};

subtest 'the streaming reader skips a 1xx before the stream too' => sub {
  my @got;
  my $handler = $client->_stream_handler('GET /v1.41/events', 'on_event',
    sub { push @got, $_[0] }, 0);
  my $raw = "HTTP/1.1 100 Continue\r\n\r\n"
    . "HTTP/1.1 200 OK\r\n"
    . "Transfer-Encoding: chunked\r\n\r\n"
    . qq(11\r\n{"status":"one"}\n\r\n)
    . "0\r\n\r\n";
  my $res = $client->_read_streaming_response(
    string_handle($raw), 'GET', $handler, {});
  is $res->[0], 200, 'the stream reader also passes the 100 by';
  is_deeply [ map { $_->{status} } @got ], ['one'],
    'and the real event reaches the callback';
};

# ---------------------------------------------------------------------------
subtest '_read_chunked: hex sizes, upper and lower case' => sub {
  # 'a' and 'A' are both 10 -- hex() is case-insensitive, and so must this be.
  my $raw = "a\r\n0123456789\r\nA\r\nABCDEFGHIJ\r\n0\r\n\r\n";
  my $fh = string_handle($raw);
  is $client->_read_chunked($fh), '0123456789ABCDEFGHIJ',
    'lowercase and uppercase hex chunk sizes both read correctly';
};

subtest '_read_chunked: a single zero-size chunk terminates immediately' => sub {
  my $fh = string_handle("0\r\n\r\n");
  is $client->_read_chunked($fh), '', 'empty body, no chunks';
};

subtest '_read_chunked: a chunk arriving in several reads' => sub {
  my $data = "b\r\nhello world\r\n0\r\n\r\n"; # 'b' hex = 11 = length("hello world")
  tie *FH, 'Test::RoleHTTP::PartialReader', $data, 3; # 3 bytes per read() call
  my $body = $client->_read_chunked(\*FH);
  is $body, 'hello world',
    'chunk payload reassembled correctly across multiple short reads';
  untie *FH;
};

# ---------------------------------------------------------------------------
subtest '_uri_encode: what it escapes and what it leaves alone' => sub {
  # Called as a bare function everywhere in the module (see _request's
  # query-string assembly) -- not as a method. Calling it as $client->
  # _uri_encode(...) would silently shift $client into the $str slot, since
  # the sub only unpacks a single positional argument.
  my $encode = \&API::Docker::Role::HTTP::_uri_encode;

  is $encode->('alpine:latest'), 'alpine:latest',
    'colon is left raw -- image references keep their tag separator';
  is $encode->('myrepo/app:v1'), 'myrepo/app:v1',
    'slash is left raw too -- image references keep their path shape';
  is $encode->('abcXYZ019-_.~'), 'abcXYZ019-_.~',
    'unreserved characters (alnum - _ . ~) are never escaped';
  is $encode->('a b'), 'a%20b', 'space is percent-encoded';
  is $encode->('foo?bar=baz'), 'foo%3Fbar%3Dbaz',
    '? and = are percent-encoded';
  is $encode->('100%'), '100%25', 'a literal percent sign is escaped itself';
  is $encode->("a\nb"), 'a%0Ab', 'control characters are escaped, not passed through';

  # A character string -- what a name/tag/author/comment/search term arrives as
  # under `use utf8` or through a :utf8 layer -- is escaped by its UTF-8 bytes,
  # not by its codepoint. The old code took ord() of the character, so 'ü'
  # became %FC (not even valid UTF-8) and '中' became %4E2D.
  is $encode->("\x{4E2D}"), '%E4%B8%AD',
    'a wide character is escaped by its UTF-8 bytes, not its codepoint';
  {
    my $u = "\x{00FC}";
    utf8::upgrade($u); # what a decoded 'ü' is: codepoint 252, the utf8 flag on
    is $encode->($u), '%C3%BC',
      'a Latin-1 character with the utf8 flag is UTF-8 encoded before escaping';
  }

  # The other half, and the reason the encoding is not unconditional: a byte
  # string is already octets and must be escaped as-is. encode_json hands a
  # HASH param (filters among them) its UTF-8 bytes, and re-encoding those would
  # turn %C3%BC into %C3%83%C2%BC -- trading this bug for a broader one.
  is $encode->("\xC3\xBC"), '%C3%BC',
    'a byte string of UTF-8 octets is escaped as-is, never double-encoded';
};

# ---------------------------------------------------------------------------
subtest '_request: assembles the request line, headers and body' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  subtest 'plain GET, no body' => sub {
    $t->_request('GET', '/containers/json');
    my $req = $t->written;
    like $req, qr{\AGET /v1\.41/containers/json HTTP/1\.1\r\n},
      'method, versioned path, and protocol on the request line';
    like $req, qr{Host: localhost\r\n}, 'Host header sent';
    like $req, qr{Connection: close\r\n}, 'Connection: close sent';
    like $req, qr{User-Agent: API-Docker\r\n}, 'User-Agent sent';
    unlike $req, qr{Content-Type}, 'no Content-Type without a body';
    unlike $req, qr{Content-Length}, 'no Content-Length without a body';
    like $req, qr{\r\n\r\n\z}, 'request ends on the blank line, empty body';
  };

  subtest 'POST with a JSON body' => sub {
    $t->_request('POST', '/containers/create', body => { Image => 'alpine:3' });
    my $req = $t->written;
    my $encoded = encode_json({ Image => 'alpine:3' });
    like $req, qr{\APOST /v1\.41/containers/create HTTP/1\.1\r\n},
      'request line for the POST';
    like $req, qr{Content-Type: application/json\r\n}, 'JSON content type';
    like $req, qr{Content-Length: @{[ length $encoded ]}\r\n},
      'content-length matches the encoded body';
    like $req, qr{\r\n\r\n\Q$encoded\E\z}, 'body follows the blank line verbatim';
  };

  subtest 'raw_body + content_type (tarball upload)' => sub {
    my $tar = "fake tar bytes\0\0\0";
    $t->_request('POST', '/build', raw_body => $tar, content_type => 'application/x-tar');
    my $req = $t->written;
    like $req, qr{Content-Type: application/x-tar\r\n},
      'content type overridden for a raw body, not left as application/json';
    like $req, qr{Content-Length: @{[ length $tar ]}\r\n},
      'content-length matches the raw body, not a JSON encoding of it';
    like $req, qr{\r\n\r\n\Q$tar\E\z}, 'raw bytes appended verbatim';
  };

  subtest 'params: sorted, hashref values JSON-encoded, then URI-encoded' => sub {
    $t->_request('GET', '/images/json',
      params => { all => 1, filters => { dangling => ['true'] } });
    my $req = $t->written;
    my ($request_line) = $req =~ /\A(GET [^\r\n]+)\r\n/;
    my $expected_filters = API::Docker::Role::HTTP::_uri_encode(
      encode_json({ dangling => ['true'] }));
    is $request_line,
      "GET /v1.41/images/json?all=1&filters=$expected_filters HTTP/1.1",
      'params sorted alphabetically by key; a hashref value is JSON-encoded '
      . 'then URI-encoded, not encoded twice by hand';
  };

  subtest 'extra headers: sanitised and appended' => sub {
    $t->_request('POST', '/images/x/push',
      headers => { 'X-Registry-Auth' => 'e30=' });
    my $req = $t->written;
    like $req, qr{X-Registry-Auth: e30=\r\n}, 'extra header present';
  };
};

# ---------------------------------------------------------------------------
subtest '_request: a CR/LF in a header value cannot inject a second header' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  $t->_request('POST', '/images/x/push',
    headers => { 'X-Registry-Auth' => "e30=\r\nX-Injected: evil" });
  my $req = $t->written;

  unlike $req, qr{\r\nX-Injected:},
    'no second header line -- "X-Injected" never starts its own line';
  like $req, qr{X-Registry-Auth: e30=X-Injected: evil\r\n},
    'the CRLF is stripped, not left as a line break -- the payload is '
    . 'flattened onto the one header line it belongs to';
};

# ---------------------------------------------------------------------------
# karr k11: the value above is sanitised, but the *name* used to go on the
# wire untouched, so a caller-supplied key could open a header line of its
# own. Names are rejected rather than stripped -- see the reasoning in
# API::Docker::Role::HTTP under "Header names are rejected, header values are
# stripped".
subtest '_request: an invalid header name is refused, not rewritten' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  subtest 'CRLF in the name croaks and sends nothing' => sub {
    eval {
      $t->_request('POST', '/images/x/push',
        headers => { "X-Registry-Auth\r\nX-Injected" => 'evil' });
    };
    like $@, qr/invalid header name/, 'croaked';
    like $@, qr/\QX-Registry-Auth\x0D\x0AX-Injected\E/,
      'the offending name is shown with its control bytes escaped, so the '
      . 'message stays on one line and names what was actually passed';
    my $message = "$@";
    unlike $message, qr/\r/, 'the croak itself carries no raw CR';
    $message =~ s/\n\z//;
    unlike $message, qr/\n/,
      'and no LF beyond the one Carp ends on -- the escaped name cannot open '
      . 'a line of its own in whatever logs the failure';
    is $t->_sink, undef,
      'no socket was even opened -- the name is checked while the request is '
      . 'assembled, so nothing reached the daemon';
  };

  subtest 'the separators that would corrupt the line, injection or not' => sub {
    my %bad = (
      'an embedded space'       => 'X Registry Auth',
      'a trailing colon'        => 'X-Registry-Auth:',
      'a bare LF'               => "tail\n",
      'a bare CR'               => "tail\r",
      'the empty string'        => '',
      'a non-ASCII byte'        => "X-Caf\xE9",
    );
    for my $why (sort keys %bad) {
      eval { $t->_request('GET', '/x', headers => { $bad{$why} => 'v' }) };
      like $@, qr/invalid header name/, "$why is rejected";
    }
  };

  subtest 'a name is refused even when its value would skip the header' => sub {
    # An undef value means the header is not sent, but the name is still a
    # caller bug and is still reported.
    eval { $t->_request('GET', '/x', headers => { "bad\r\nname" => undef }) };
    like $@, qr/invalid header name/,
      'validated before the defined-check on the value';
  };

  subtest 'every character an RFC 9110 token allows still passes' => sub {
    my $token = "Abc123-!#\$%&'*+.^_`|~";
    $t->_request('GET', '/x', headers => { $token => 'ok' });
    like $t->written, qr/\Q$token\E: ok\r\n/,
      'the full token charset is accepted, not just the alphanumerics';

    $t->_request('POST', '/images/x/push',
      headers => { 'X-Registry-Auth' => 'e30=' });
    like $t->written, qr/X-Registry-Auth: e30=\r\n/,
      'and the one name this distribution actually sends is unaffected';
  };
};

# ---------------------------------------------------------------------------
# karr k102: $path is caller data (a container name, an image reference)
# spliced straight into the request line, and unlike a header value it was
# never checked. Measured through the real _request against a fake socket:
# containers->inspect("x HTTP/1.1\r\nX-Evil: 1\r\n\r\nGET /y") put
# 'GET /v1.41/containers/x HTTP/1.1\r\nX-Evil: 1\r\n\r\n...' on the wire -- the
# name ended the request line and opened a header of its own. A path outside
# the request-target character set is now refused, not written; see
# API::Docker::Role::HTTP under "A request path is rejected, not sanitised".
subtest '_request: a path outside the request-target charset is refused' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  subtest 'the measured injection: CRLF in the path croaks and sends nothing' => sub {
    my $evil = "x HTTP/1.1\r\nX-Evil: 1\r\n\r\nGET /y";
    eval { $t->_request('GET', "/containers/$evil/json") };
    like $@, qr/invalid request path/, 'croaked';
    like $@, qr/\Qx HTTP\E.*\Q\x0D\x0AX-Evil\E/,
      'the offending path is shown with its control bytes escaped, so the '
      . 'message stays on one line and names what was actually passed';
    my $message = "$@";
    unlike $message, qr/\r/, 'the croak itself carries no raw CR';
    $message =~ s/\n\z//;
    unlike $message, qr/\n/,
      'and no LF beyond the one Carp ends on -- the escaped path cannot open a '
      . 'line of its own in whatever logs the failure';
    is $t->_sink, undef,
      'no socket was even opened -- the path is checked while the request is '
      . 'assembled, so nothing reached the daemon';
  };

  subtest 'each separator that would rewrite the request target' => sub {
    my %bad = (
      'a space (opens the HTTP-version field)' => 'na me',
      'a bare CR'                              => "tail\r",
      'a bare LF'                              => "tail\n",
      'a ? (opens the query string)'          => 'na?me',
      'a # (opens the fragment)'              => 'na#me',
      'a non-ASCII byte'                      => "caf\xE9",
      'a NUL byte'                            => "na\x00me",
    );
    for my $why (sort keys %bad) {
      my $t2 = Test::API::Docker::FakeTransport->new(
        host        => 'unix:///nonexistent.sock',
        api_version => '1.41',
      );
      eval { $t2->_request('GET', "/containers/$bad{$why}/json") };
      like $@, qr/invalid request path/, "$why is rejected";
      is $t2->_sink, undef, "$why: nothing reached the wire";
    }
  };

  subtest 'a legitimate image reference still assembles verbatim' => sub {
    # ':' tag, '/' path and '@sha256:...' digest all survive -- the charset
    # that closes the injection is the one image references live in, so the
    # check must not be a false positive on any of them.
    $t->_request('POST', '/images/library/nginx:1.25/push');
    like $t->written,
      qr{\APOST /v1\.41/images/library/nginx:1\.25/push HTTP/1\.1\r\n},
      'a tagged, namespaced reference is written, not rejected';

    my $digest = 'nginx@sha256:' . ('a' x 64);
    $t->_request('GET', "/images/$digest/json");
    like $t->written,
      qr{\AGET /v1\.41/images/nginx\@sha256:@{[ 'a' x 64 ]}/json HTTP/1\.1\r\n},
      'a digest reference (@ and :) is written verbatim too';
  };

  subtest 'measured end to end through the resource method' => sub {
    # Exactly the ticket's measurement: the malicious name arrives through
    # containers->inspect, which builds /containers/$id/json. The injection is
    # closed at the transport, whatever resource method assembled the path.
    my $t3 = Test::API::Docker::FakeTransport->new(
      host        => 'unix:///nonexistent.sock',
      api_version => '1.41',
    );
    eval { $t3->containers->inspect("x HTTP/1.1\r\nX-Evil: 1\r\n\r\nGET /y") };
    like $@, qr/invalid request path/, 'refused before it reaches the wire';
    is $t3->_sink, undef, 'and no socket was opened';
  };
};

# ---------------------------------------------------------------------------
subtest '_request: >= 400 croaks' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  subtest 'a JSON error body croaks with its message, not the raw body' => sub {
    $t->canned([404, 'Not Found', {}, encode_json({ message => 'no such container: abc' })]);
    eval { $t->_request('GET', '/containers/abc/json') };
    like $@, qr/\ADocker API error \(404\): no such container: abc at /,
      'the decoded message is used, the JSON envelope is not';
  };

  subtest 'a non-JSON error body croaks with the raw body' => sub {
    $t->canned([500, 'Internal Server Error', {}, 'internal server meltdown']);
    eval { $t->_request('GET', '/containers/abc/json') };
    like $@, qr/\ADocker API error \(500\): internal server meltdown at /,
      'a body that does not look like JSON is never handed to decode_json';
  };

  subtest 'a body that looks like JSON but is not valid falls back to the raw body' => sub {
    $t->canned([400, 'Bad Request', {}, '{not actually json']);
    eval { $t->_request('POST', '/containers/create') };
    like $@, qr/\Q{not actually json\E/,
      'decode_json failing inside the eval leaves the raw body as the message';
  };

  subtest 'a JSON array error body (no .message key) falls back to the raw body' => sub {
    # decode_json succeeds here, but $data->{message} on an arrayref dies --
    # caught by the same eval, so the raw body still surfaces rather than an
    # unrelated "Not a HASH reference" replacing the real error.
    $t->canned([400, 'Bad Request', {}, '[1,2,3]']);
    eval { $t->_request('POST', '/containers/create') };
    like $@, qr/\ADocker API error \(400\): \[1,2,3\] at /,
      'array-shaped error body is used verbatim, not blamed for a deref error';
  };

  # karr k13: Podman answers a failed push with 500 and the stream-shaped
  # body {"errorDetail":{"message":...},"error":...} -- no `message` key at
  # all -- so the whole JSON object became the croak text.
  subtest 'a JSON error body with errorDetail but no message uses errorDetail.message' => sub {
    $t->canned([500, 'Internal Server Error', {}, encode_json({
      errorDetail => { message => 'denied: requested access to the resource is denied' },
      error       => 'denied: requested access to the resource is denied',
    })]);
    eval { $t->_request('POST', '/images/x/push') };
    like $@, qr/\ADocker API error \(500\): denied: requested access to the resource is denied at /,
      'errorDetail.message is the reason, not the raw JSON object';
  };

  subtest 'a JSON error body with only a flat error key uses that' => sub {
    $t->canned([500, 'Internal Server Error', {}, encode_json({ error => 'flat error text' })]);
    eval { $t->_request('POST', '/images/x/push') };
    like $@, qr/\ADocker API error \(500\): flat error text at /,
      'the flat error key is the last fallback before the raw body';
  };

  subtest 'message still wins when it is present beside errorDetail' => sub {
    $t->canned([500, 'Internal Server Error', {}, encode_json({
      message     => 'the message key',
      errorDetail => { message => 'the detail' },
    })]);
    eval { $t->_request('POST', '/images/x/push') };
    like $@, qr/\ADocker API error \(500\): the message key at /,
      'message is consulted first, errorDetail only fills its absence';
  };

  # karr k50: the croak text is engine-specific prose -- Podman and Docker
  # word the same 409 differently -- so a caller telling 404 from 409 apart
  # had to match on it. The status code goes on the exception instead, and
  # the exception has to stay indistinguishable from the string it replaces.
  subtest 'the exception carries the status and is still that exact string' => sub {
    my $body = encode_json({
      cause    => 'container state improper',
      message  => 'can only kill running containers. abc is in state stopped',
      response => 409,
    });
    $t->canned([409, 'Conflict', {}, $body]);
    my $err = do { local $@; eval { $t->_request('POST', '/containers/abc/kill') }; $@ };

    isa_ok $err, 'API::Docker::Error::HTTP';
    is $err->status, 409, 'the status code, as the thing to branch on';
    is $err->reason, 'Conflict', 'the reason phrase off the status line';
    is $err->body, $body, 'the response body verbatim';
    is $err->data->{cause}, 'container state improper',
      'and decoded, so an engine-specific extra key is reachable';

    is "$err", $err->message . $err->location,
      'stringification is the message plus Carp\'s location, nothing else';
    like "$err", qr/\ADocker API error \(409\): can only kill running containers\. abc is in state stopped at \S+ line \d+\.?\n\z/,
      'which is byte for byte what the plain croak produced before';
    unlike $err->message, qr/ at \S+ line \d+/,
      'the message alone carries no location';
    ok $err, 'and the boolean overload is true even before stringifying';
  };

  subtest 'a body that could not be decoded leaves data undef' => sub {
    $t->canned([400, 'Bad Request', {}, '{not actually json']);
    my $err = do { local $@; eval { $t->_request('POST', '/containers/create') }; $@ };
    is $err->data, undef, 'nothing is invented where decode_json failed';
    is $err->body, '{not actually json', 'while the raw body is still there';
  };

  subtest '204 and other success codes still return undef/decode normally' => sub {
    $t->canned([204, 'No Content', {}, '']);
    is $t->_request('POST', '/containers/abc/start'), undef, '204 -> undef';

    $t->canned([200, 'OK', {}, '{"Id":"abc"}']);
    is_deeply $t->_request('GET', '/containers/abc/json'), { Id => 'abc' },
      'a 2xx JSON body still decodes';
  };
};

# ---------------------------------------------------------------------------
# karr k16: a HEAD response repeats the header fields the equivalent GET would
# send -- Content-Length among them -- and then sends no body at all. Reading
# one waits for bytes that never arrive. The bytes after the blank line below
# stand in for whatever comes next on the connection: consuming them as a body
# is exactly the bug, and a handle that simply hit EOF there would hide it (the
# old code returned '' there too, from a read that failed rather than from one
# it never made).
#
# Where "not consumed" is now read: since karr k60 the read-ahead past the
# header block sits in the transport's own buffer rather than in PerlIO's, so
# the question is asked of that buffer. The claim is unchanged -- these bytes
# were not taken as a body -- and it is now asked somewhere this code owns
# rather than of a buffer it could not see into.
subtest '_read_response: a HEAD response has no body, whatever it announces' => sub {
  subtest 'an announced content-length is not read' => sub {
    my $raw = "HTTP/1.1 200 OK\r\n"
      . "Content-Length: 13\r\n"
      . "X-Docker-Container-Path-Stat: e30=\r\n"
      . "\r\n"
      . 'NOT-THE-BODY!';
    my $fh = string_handle($raw);
    my $resp = $client->_read_response($fh, 'HEAD');

    is $resp->[3], '', 'body is empty';
    is $resp->[2]{'content-length'}, '13',
      'the announced length is still collected as a header';
    is $resp->[2]{'x-docker-container-path-stat'}, 'e30=',
      'and so is the header a HEAD response carries its payload in';
    is unconsumed($client, $fh), 'NOT-THE-BODY!',
      'the bytes after the headers are still unconsumed, not swallowed as a '
      . 'body that was never sent';
  };

  subtest 'a chunked announcement is not read either' => sub {
    my $raw = "HTTP/1.1 200 OK\r\n"
      . "Transfer-Encoding: chunked\r\n"
      . "\r\n"
      . "5\r\nhello\r\n0\r\n\r\n";
    my $fh = string_handle($raw);
    my $resp = $client->_read_response($fh, 'HEAD');

    is $resp->[3], '', 'body is empty';
    is unconsumed($client, $fh), "5\r\nhello\r\n0\r\n\r\n",
      'the chunk framing was not consumed';
  };

  subtest 'every other method still reads its body' => sub {
    my $raw = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}";
    my $fh = string_handle($raw);
    is $client->_read_response($fh, 'GET')->[3], '{}', 'a GET body is read';

    my $fh2 = string_handle($raw);
    is $client->_read_response($fh2)->[3], '{}',
      'and so is one read without a method argument at all';
  };
};

# ---------------------------------------------------------------------------
# karr k16: _request used to drop the status line and the response headers, so
# 304 ("it was already in that state") and 204 ("changed it") were both undef,
# and a header carrying the whole payload was unreachable.
subtest '_request: the response out-parameter' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  subtest '204 and 304 are told apart' => sub {
    $t->canned([204, 'No Content', {}, '']);
    my %changed;
    is $t->_request('POST', '/containers/abc/start', response => \%changed), undef,
      'the return value is unchanged -- an empty body is still undef';
    is $changed{status}, 204, 'the status code is handed out';
    is $changed{reason}, 'No Content', 'and the reason phrase with it';

    $t->canned([304, 'Not Modified', {}, '']);
    my %unchanged;
    is $t->_request('POST', '/containers/abc/start', response => \%unchanged), undef,
      'a 304 carries no body either';
    is $unchanged{status}, 304,
      '304 is reported as 304 -- the two are indistinguishable by return '
      . 'value, and this is the only thing that separates them';
  };

  subtest 'the response headers are handed out, lowercased' => sub {
    $t->canned([200, 'OK', { 'x-docker-container-path-stat' => 'e30=' }, '']);
    my %res;
    $t->_request('HEAD', '/containers/abc/archive', response => \%res);
    is $res{headers}{'x-docker-container-path-stat'}, 'e30=',
      'the header a HEAD response carries its payload in is reachable';
  };

  subtest 'the hash is filled before the >= 400 croak' => sub {
    $t->canned([404, 'Not Found', {}, encode_json({ message => 'no such container: abc' })]);
    my %res;
    eval { $t->_request('GET', '/containers/abc/json', response => \%res) };
    like $@, qr/\ADocker API error \(404\)/, 'still croaks';
    is $res{status}, 404,
      'and the status survives the croak -- an eval-ing caller is not left '
      . 'with an empty hash';
  };

  subtest 'the hash is overwritten, not merged' => sub {
    $t->canned([200, 'OK', {}, '{}']);
    my %res = (status => 999, stale => 'from an earlier call');
    $t->_request('GET', '/containers/abc/json', response => \%res);
    is $res{status}, 200, 'the status of this call, not the previous one';
    ok !exists $res{stale}, 'nothing of the previous call is left behind';
  };

  subtest 'anything but a HashRef is a caller bug' => sub {
    my $t2 = Test::API::Docker::FakeTransport->new(
      host        => 'unix:///nonexistent.sock',
      api_version => '1.41',
    );
    eval { $t2->_request('GET', '/containers/json', response => []) };
    like $@, qr/response option must be a HashRef/, 'croaked on an ArrayRef';
    is $t2->_sink, undef,
      'no socket was opened -- checked while the request is assembled, like a '
      . 'header name, so nothing reached the daemon';
  };

  subtest 'without the option nothing changes' => sub {
    $t->canned([200, 'OK', {}, '{"Id":"abc"}']);
    is_deeply $t->_request('GET', '/containers/abc/json'), { Id => 'abc' },
      'the default return shape is untouched';
  };
};

# ---------------------------------------------------------------------------
subtest 'head: sends HEAD, returns undef, payload comes out of the headers' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );
  # Captured from Podman 5.4.2 (API 1.41):
  # HEAD /v1.41/containers/{id}/archive?path=/etc/hostname
  my $stat = 'eyJuYW1lIjoiaG9zdG5hbWUiLCJzaXplIjoxMywibW9kZSI6NDIwfQ==';
  $t->canned([200, 'OK', { 'x-docker-container-path-stat' => $stat }, '']);

  my %res;
  is $t->head('/containers/abc/archive',
    params   => { path => '/etc/hostname' },
    response => \%res,
  ), undef, 'a HEAD response has no body, so there is nothing to return';

  my ($request_line) = $t->written =~ /\A([^\r\n]+)\r\n/;
  is $request_line,
    'HEAD /v1.41/containers/abc/archive?path=/etc/hostname HTTP/1.1',
    'HEAD on the versioned path, query parameters appended as for any verb';
  is $res{status}, 200, 'the status line is reachable';
  is $res{headers}{'x-docker-container-path-stat'}, $stat,
    'and the header the whole payload rides in';
};

# ---------------------------------------------------------------------------
# karr k16, end to end: t/containers.t drives these through the mock, which
# replaces _request wholesale. This drives the real transport, so a _request
# that stopped passing the status on would fail here while the mocked test
# still passed.
subtest 'containers: 204 means it changed, 304 means it was already so' => sub {
  my $t = Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  $t->canned([204, 'No Content', {}, '']);
  is $t->containers->start('abc'), 1, 'start: 204 -> it was started';
  is $t->containers->stop('abc'), 1, 'stop: 204 -> it was stopped';
  is $t->containers->restart('abc'), 1, 'restart: 204 -> it was restarted';
  is $t->containers->pause('abc'), 1, 'pause: 204 -> it was paused';
  is $t->containers->unpause('abc'), 1, 'unpause: 204 -> it was unpaused';

  $t->canned([304, 'Not Modified', {}, '']);
  is $t->containers->start('abc'), 0,
    'start: 304 -> it was already running (this is what used to be undef)';
  is $t->containers->stop('abc'), 0, 'stop: 304 -> it was already stopped';
  ok !$t->containers->start('abc'),
    'and 0 is still false, so a caller that only tests truth or ignores the '
    . 'value sees exactly what it saw before';
};

done_testing;
