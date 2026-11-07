use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use IO::Socket::INET;
use Test::More;
use Time::HiRes qw(time);

use App::WebPerimeterScan::HTTP;

# White-box: _parse_head is private.
$Sub::Private::BYPASS = 1;

subtest 'errors that need no network' => sub {
	my $http = App::WebPerimeterScan::HTTP->new(delay => 0);

	is($http->fetch('not a url')->{error}, 'invalid URL', 'an unparsable URL');
	is($http->fetch('ftp://example.com/')->{error}, "unsupported scheme 'ftp'", 'a non-HTTP scheme');
	is($http->fetch('http:///path')->{error}, 'URL has no host', 'a URL without a host');
	is($http->requests, 0, 'nothing was sent');

	ok(!eval { $http->fetch('http://example.com/', method => "GET / HTTP/1.1\r\nX: y"); 1 },
		'a method that could split the request line is refused');
	ok(!eval { App::WebPerimeterScan::HTTP->new(timeout => -1); 1 }, 'a negative timeout is refused');
	ok(!eval { App::WebPerimeterScan::HTTP->new(bogus => 1); 1 }, 'an unknown argument is refused');
};

subtest 'a connect failure does not report a stale TLS error' => sub {
	# A bound port that is not listening refuses the connection.
	my $closed = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp')
		or plan skip_all => 'cannot bind a port';

	local $IO::Socket::SSL::SSL_ERROR = 'stale error from an earlier TLS failure';
	my $res = App::WebPerimeterScan::HTTP->new(delay => 0, timeout => 2)->fetch('http://127.0.0.1:' . $closed->sockport . '/');

	like($res->{error}, qr/\Aconnect failed: /, 'the connect failure is reported');
	unlike($res->{error}, qr/stale/, 'the TLS error of another connection is not');
	is($res->{port}, $closed->sockport, 'the port is included');
};

subtest 'header parsing' => sub {
	my $head = App::WebPerimeterScan::HTTP::_parse_head(
		"HTTP/1.1 200 OK\r\nSet-Cookie: a=1\r\nset-cookie: b=2; Expires=Wed, 01 Jan 2031 00:00:00 GMT\r\nX-Folded: one\r\n  two\r\nBad line\r\nName :value"
	);
	is($head->{status}, 200, 'status');
	is($head->{reason}, 'OK', 'reason');
	is_deeply($head->{headers}{'set-cookie'}, [ 'a=1', 'b=2; Expires=Wed, 01 Jan 2031 00:00:00 GMT' ],
		'every Set-Cookie is kept separately, commas and all');
	is($head->{headers}{'x-folded'}[0], 'one two', 'an obs-fold continuation is joined');
	is($head->{headers}{name}[0], 'value', 'white space before the colon is trimmed');
	ok(!exists $head->{headers}{'bad line'}, 'a line without a colon is ignored');
	is(App::WebPerimeterScan::HTTP::_parse_head("SSH-2.0-OpenSSH_9.6\r\n"), undef, 'a non-HTTP reply is refused');
};

# plan skip_all is only valid before the first test, and the subtests above
# have run, so stop here with done_testing instead.
if($^O eq 'MSWin32') {
	note('skipping the loopback server tests: the test server needs fork');
	done_testing();
	exit 0;
}
require TestServer;

my $server = TestServer->start(
	'/' => sub {
		my ($request) = @_;
		return [ 200, [ 'Set-Cookie: a=1', 'Set-Cookie: b=2', 'Content-Type: text/html' ], $request->{request} ];
	},
	'/chunked' => "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5;ext=1\r\nhello\r\n6\r\n world\r\n0\r\nTrailer: x\r\n\r\n",
	'/empty'   => [ 204, [], '' ],
	'/big'     => [ 200, [], 'x' x 5000 ],
	'/eof'     => "HTTP/1.1 200 OK\r\n\r\nread to the end",
	'/garbage' => "this is not HTTP\r\n\r\n",
);
unless($server) {
	note('skipping the loopback server tests: cannot start the test server');
	done_testing();
	exit 0;
}

my $http = App::WebPerimeterScan::HTTP->new(delay => 0, timeout => 5, max_size => 1000);

my $res = $http->fetch($server->url('/'), headers => [ 'X-Test: yes', "X-Evil: a\r\nInjected: b" ]);
is($res->{status}, 200, 'a plain GET');
is_deeply($res->{set_cookie}, [ 'a=1', 'b=2' ], 'both cookies arrive');
is($res->{content_type}, 'text/html', 'content type');
like($res->{body}, qr{\AGET / HTTP/1\.1\r\n}, 'the request line');
like($res->{body}, qr{^Host: 127\.0\.0\.1:\d+\r$}m, 'Host carries the non-default port');
like($res->{body}, qr{^User-Agent: webperimeter/\Q$App::WebPerimeterScan::HTTP::VERSION\E }m, 'the User-Agent names the release');
like($res->{body}, qr{^X-Test: yes\r$}m, 'an extra header is sent');
unlike($res->{body}, qr{Injected}, 'a header containing CR/LF is dropped');
is($http->header($res, 'SET-COOKIE'), 'b=2', 'header() returns the last value, any case');
is($http->header($res, 'missing'), undef, 'header() of an absent header');
like($res->{raw_headers}, qr{\AHTTP/1\.1 200}, 'the raw header block is kept');

is($http->fetch($server->url('/chunked'))->{body}, 'hello world', 'a chunked body is decoded, extensions and trailers ignored');
is($http->fetch($server->url('/empty'))->{body}, '', 'a 204 has no body');

my $big = $http->fetch($server->url('/big'));
is(length $big->{body}, 1000, 'the body is cut at max_size');
ok($big->{truncated}, '... and marked truncated');

is($http->fetch($server->url('/eof'))->{body}, 'read to the end', 'a body with no length is read to EOF');
is($http->fetch($server->url('/garbage'))->{error}, 'malformed status line', 'a non-HTTP reply is an error');

like($http->fetch($server->url('/'), method => 'OPTIONS')->{body}, qr{\AOPTIONS / }, 'the method is sent');
is($http->fetch($server->url('/'), method => 'HEAD')->{body}, '', 'a HEAD response has no body');

is($http->requests, 8, 'every request that connected is counted');

# The throttle: two requests to one host are at least 'delay' apart.
my $slow = App::WebPerimeterScan::HTTP->new(delay => 0.3);
$slow->fetch($server->url('/empty'));
my $started = time;
$slow->fetch($server->url('/empty'));
cmp_ok(time - $started, '>=', 0.25, 'the per-host delay is honoured');

$server->stop;

done_testing();
