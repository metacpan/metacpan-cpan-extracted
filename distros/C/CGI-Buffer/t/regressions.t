#!perl -w

# Regression tests for bugs fixed in the HTTP handling, compression, the cache
# and optimise_content

use strict;
use warnings;
use Digest::MD5;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Most;
use Test::TempDir::Tiny;
use Test::CGIBuffer qw(run_script second_request header);

my $have_chi = eval { require CHI; 1 };

my $text = q{print "Content-Type: text/plain\n\nhello world";};

subtest 'Range' => sub {
	my %tests = (
		'bytes=-5' => ['world', 'bytes 6-10/11'],
		'bytes=0-4' => ['hello', 'bytes 0-4/11'],
		'bytes=6-' => ['world', 'bytes 6-10/11'],
		'bytes=6-100' => ['world', 'bytes 6-10/11'],
	);
	foreach my $range(sort keys %tests) {
		my $r = run_script(code => $text, env => { HTTP_RANGE => $range, HTTP_ACCEPT_ENCODING => 'gzip' });
		is($r->{body}, $tests{$range}->[0], "$range body");
		is_deeply([header($r, 'Status')], ['206 Partial Content'], "$range status");
		is_deeply([header($r, 'Content-Range')], [$tests{$range}->[1]], "$range Content-Range");
		is_deeply([header($r, 'Content-Encoding')], [], "$range is not compressed");
	}

	my $r = run_script(code => $text, env => { HTTP_RANGE => 'bytes=20-' });
	is_deeply([header($r, 'Status')], ['416 Range Not Satisfiable'], 'unsatisfiable range gives 416');
	is_deeply([header($r, 'Content-Range')], ['bytes */11'], '416 Content-Range');
	is($r->{body}, '', '416 has no body');

	is(run_script(code => $text, env => { HTTP_RANGE => 'bytes=5-2' })->{body}, 'hello world', 'backwards range is ignored');
	is(run_script(code => $text, env => { HTTP_RANGE => 'bytes=0-4', REQUEST_METHOD => 'POST' })->{body},
		'hello world', 'range is ignored for POST');

	$r = run_script(
		code => q{print "Status: 200 OK\nContent-Type: text/plain\n\nhello world";},
		env => { HTTP_RANGE => 'bytes=0-4' }
	);
	is($r->{body}, 'hello', 'script\'s own Status header');
	is_deeply([header($r, 'Status')], ['206 Partial Content'], 'only the 206 is sent');

	$r = run_script(
		code => q{print "Content-Type: text/plain; charset=utf-8\n\ncaf\xc3\xa9 au lait";},
		env => { HTTP_RANGE => 'bytes=0-4' }
	);
	is($r->{body}, "caf\xc3\xa9", 'ranges are in bytes');

	is(run_script(code => $text, env => { HTTP_RANGE => 'bytes=0-4', HTTP_IF_RANGE => '"not-the-etag"' })->{body},
		'hello world', 'If-Range that does not match gives the whole page');
};

subtest '304 and If-None-Match' => sub {
	my $etag = '"' . Digest::MD5::md5_hex('hello world') . '"';
	my $code = q{print "Status: 200 OK\nContent-Type: text/plain\n\nhello world";};

	foreach my $inm($etag, qq{"aaa", $etag}, "W/$etag", '*') {
		my $r = run_script(code => $code, env => { HTTP_IF_NONE_MATCH => $inm });
		is_deeply([header($r, 'Status')], ['304 Not Modified'], "If-None-Match: $inm gives one 304");
		is($r->{body}, '', 'no body');
		is_deeply([header($r, 'Content-Encoding')], [], 'no Content-Encoding');
	}

	my $r = run_script(code => $code, env => { HTTP_IF_NONE_MATCH => $etag, REQUEST_METHOD => 'POST' });
	is_deeply([header($r, 'Status')], ['412 Precondition Failed'], 'matching If-None-Match on POST gives 412');

	$r = run_script(
		code => q{print "Status: 404 Not Found\nContent-Type: text/plain\n\nnot here";},
		init => 'info => CGI::Info->new()',
		preamble => "use CGI::Info;\n",
		env => { HTTP_IF_MODIFIED_SINCE => 'Fri, 01 Jan 2100 00:00:00 GMT' },
	);
	is_deeply([header($r, 'Status')], ['404 Not Found'], 'If-Modified-Since leaves a 404 alone');

	foreach my $protocol('HTTP/2', 'HTTP/3') {
		is(scalar(header(run_script(code => $code, env => { SERVER_PROTOCOL => $protocol }), 'ETag')), 1, "ETag for $protocol");
	}
};

subtest 'Headers' => sub {
	my $r = run_script(
		code => q{print "Content-Type: text/plain\nContent-Length: 999\n\n", 'x' x 100;},
		env => { HTTP_ACCEPT_ENCODING => 'gzip' }
	);
	is_deeply([header($r, 'Content-Length')], [length($r->{body})], 'the script\'s Content-Length is replaced');

	$r = run_script(
		code => q{print "Content-Type: text/plain\nContent-Encoding: gzip\n\n", 'x' x 100;},
		env => { HTTP_ACCEPT_ENCODING => 'gzip' }
	);
	is($r->{body}, 'x' x 100, 'output that the script encoded is not compressed again');
	is_deeply([header($r, 'Content-Encoding')], ['gzip'], 'one Content-Encoding');

	$r = run_script(code => q{print "Content-Type: text/plain\nStatus: 404 Not Found\n\nnot here";});
	is_deeply([header($r, 'Status')], ['404 Not Found'], 'headers ending in LF give one Status');

	is_deeply([header(run_script(code => $text), 'Vary')], ['Accept-Encoding'], 'Vary: Accept-Encoding with uncompressed output');

	$r = run_script(code => $text, env => { REQUEST_METHOD => 'HEAD' });
	like($r->{output}, qr/\r\n\r\n$/, 'a response with no body still ends its headers');
	is($r->{body}, '', 'HEAD has no body');
};

subtest 'Compression' => sub {
	my $long = q{print "Content-Type: Text/HTML\n\n<html><body>", 'hello world ' x 20, "</body></html>";};
	my $r = run_script(code => $long, env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	is_deeply([header($r, 'Content-Encoding')], ['gzip'], 'Text/HTML is compressed');
	my ($etag) = header($r, 'ETag');
	like($etag, qr/-gzip"$/, 'compressed output has its own ETag');

	$r = run_script(code => $long, env => { HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_NONE_MATCH => $etag });
	is_deeply([header($r, 'Status')], ['304 Not Modified'], 'compressed ETag matches');

	my %tests = (
		'gzip;q=0' => [],
		'gzip;q=0.8' => ['gzip'],
		'deflate , gzip' => ['gzip'],
		'identity, x-gzip' => ['gzip'],
		'GZIP' => ['gzip'],
	);
	foreach my $accept(sort keys %tests) {
		is_deeply([header(run_script(code => $long, env => { HTTP_ACCEPT_ENCODING => $accept }), 'Content-Encoding')],
			$tests{$accept}, "Accept-Encoding: $accept");
	}

	$r = run_script(
		preamble => q{BEGIN { unshift @INC, sub { die "No brotli\n" if($_[1] eq 'IO/Compress/Brotli.pm'); return } }} . "\n",
		code => $long, env => { HTTP_ACCEPT_ENCODING => 'br, gzip' }
	);
	is_deeply([header($r, 'Status')], ['200 OK'], 'no 406 when brotli is not installed');
	is_deeply([header($r, 'Content-Encoding')], ['gzip'], 'the next encoding is used');

	SKIP: {
		skip 'Compress::Zlib not installed', 2 unless(eval { require Compress::Zlib; 1 });
		$r = run_script(
			code => q{print "Content-Type: text/plain; charset=utf-8\n\n", "caf\xc3\xa9 " x 20;},
			env => { HTTP_ACCEPT_ENCODING => 'gzip' }
		);
		is_deeply([header($r, 'Content-Encoding')], ['gzip'], 'compressed');
		is(Compress::Zlib::memGunzip($r->{body}), "caf\xc3\xa9 " x 20, 'UTF-8 printed as bytes is not encoded twice');
	}
};

subtest 'Cache' => sub {
	plan skip_all => 'CHI not installed' unless($have_chi);

	my $html = q{print "Content-Type: text/html\nVary: Accept-Encoding\n\n<html><body>hello</body></html>";};
	my $dir = tempdir();
	my $r = run_script(dir => $dir, cache => 1, code => $html);
	is(scalar(header($r, 'Status')), 1, 'Vary: Accept-Encoding does not end the headers');
	is($r->{body}, '<html><body>hello</body></html>', 'body is intact');
	my ($etag) = header($r, 'ETag');

	$r = run_script(dir => $dir, cache => 1, code => $html);
	like((header($r, 'X-Cache-Lookup'))[0], qr/^HIT/, 'second request is from the cache');
	is($r->{body}, '<html><body>hello</body></html>', 'cached body is intact');

	$r = run_script(dir => $dir, cache => 1, code => $html, env => {
		HTTP_IF_NONE_MATCH => '"no-match"',
		HTTP_IF_MODIFIED_SINCE => 'Fri, 01 Jan 2100 00:00:00 GMT'
	});
	is_deeply([header($r, 'Status')], ['200 OK'], 'If-None-Match is looked at before If-Modified-Since');

	$r = run_script(dir => $dir, cache => 1, code => $html, env => { HTTP_IF_NONE_MATCH => $etag });
	is_deeply([header($r, 'Status')], ['304 Not Modified'], 'ETag of a cached page matches');

	# An ETag that the script gave keeps its quotes in the cache
	my $own = '"0123456789abcdef0123456789abcdef"';
	my $code = q{print "Content-Type: text/html\nETag: \"0123456789abcdef0123456789abcdef\"\n\n<html><body>hello</body></html>";};
	$r = second_request(cache => 1, code => $code, env => { HTTP_IF_NONE_MATCH => $own });
	is_deeply([header($r, 'Status')], ['304 Not Modified'], 'the script\'s own ETag matches from the cache');

	# Expired entries aren't used
	is(run_script(code => q{
		use CHI;
		use Storable;
		my $cache = CHI->new(driver => 'File', root_dir => "$ENV{DOCUMENT_ROOT}/cache");
		$cache->set('k', Storable::freeze({ body => 'stale', headers => 'Content-Type: text/plain' }), { expires_at => time - 60 });
		CGI::Buffer::init(cache => $cache, cache_key => 'k');
		exit if CGI::Buffer::is_cached();
		print "Content-Type: text/plain\n\nfresh";
	})->{body}, 'fresh', 'an expired entry is not used');

	# A failing cache gives a warning, and the page is still sent
	$r = run_script(code => q{
		package BadCache;
		sub new { bless {}, shift }
		sub get_object { die 'broken get' }
		sub set { die 'broken set' }
		sub get { die 'broken get' }
		package main;
		CGI::Buffer::init(cache => BadCache->new(), cache_key => 'k');
		exit if CGI::Buffer::is_cached();
		print "Content-Type: text/plain\n\nstill here";
	});
	is($r->{body}, 'still here', 'page is sent when the cache fails');
	like($r->{stderr}, qr/CGI::Buffer: reading the cache failed: broken get/, 'with a warning');

	# RT104471: an entry made before the script changed is removed, not the
	# whole cache
	$r = run_script(code => q{
		use CHI;
		use Storable;
		my $cache = CHI->new(driver => 'File', root_dir => "$ENV{DOCUMENT_ROOT}/cache");
		$cache->set('k', Storable::freeze({ body => 'old', headers => 'Content-Type: text/plain' }));
		$cache->set('other', 'kept');
		utime(time + 100, time + 100, $ENV{SCRIPT_FILENAME});	# The script has changed since
		CGI::Buffer::init(cache => $cache, cache_key => 'k');
		my $cached = CGI::Buffer::is_cached();
		print "Content-Type: text/plain\n\n", join(',', $cached, ($cache->get('k') ? 'k' : 'no k'), $cache->get('other'));
	});
	is($r->{body}, '0,no k,kept', 'the out of date entry is removed, others are kept');

	# Headers with no body, e.g. a redirection, aren't replaced by the cached
	# page with the same key
	$dir = tempdir();
	run_script(dir => $dir, cache => 1, code => $html);
	$r = run_script(dir => $dir, code => q{
		use CHI;
		CGI::Buffer::init(cache => CHI->new(driver => 'File', root_dir => "$ENV{DOCUMENT_ROOT}/cache"), cache_key => 'k');
		print "Status: 302 Found\nLocation: /elsewhere\n\n";
	});
	is_deeply([header($r, 'Status')], ['302 Found'], 'redirection is sent');
	is_deeply([header($r, 'Location')], ['/elsewhere'], 'with its Location');

	# A damaged entry is removed, and gives a 500
	$r = run_script(code => q{
		use CHI;
		use Storable;
		my $cache = CHI->new(driver => 'File', root_dir => "$ENV{DOCUMENT_ROOT}/cache");
		$cache->set('k', Storable::freeze({ headers => 'Content-Type: text/plain' }));
		CGI::Buffer::init(cache => $cache, cache_key => 'k');
		exit if CGI::Buffer::is_cached();
		print "Content-Type: text/plain\n\nnot cached";
	});
	is_deeply([header($r, 'Status')], ['500 Internal Server Error'], 'damaged entry gives a 500');
	like($r->{stderr}, qr/Can't retrieve body for key k, the entry holds: headers/, 'with a warning');
};

subtest 'Logging' => sub {
	my $r = run_script(code => q{
		package MyLogger;
		sub new { bless {}, shift }
		sub AUTOLOAD { our $AUTOLOAD; print STDERR "LOG $AUTOLOAD: @_[1..$#_]\n" unless($AUTOLOAD =~ /DESTROY/) }
		package main;
		CGI::Buffer::init(logger => MyLogger->new());
		print "Content-Type: text/plain\n\nhello";
	});
	like($r->{stderr}, qr/LOG MyLogger::debug: Initial status = 200/, 'the END block logs');
	is($r->{body}, 'hello', 'and the page is sent');
};

subtest 'lint_content' => sub {
	my $r = run_script(init => 'lint_content => 1', env => { NO_CACHE => 1 }, code => q{
		print "Content-Type: text/html\n\n<html><head><title>t</title></head><body><a href=\"x\">no end</body></html>";
	});
	is_deeply([header($r, 'Status')], ['500 Internal Server Error'], 'HTML errors give a 500');
	like($r->{body}, qr/<a> at \(\d+:\d+\) is never closed/, 'the errors are the body');
	like($r->{stderr}, qr/CGI::Buffer: \(\d+:\d+\): <a> at/, 'and are warnings');
};

subtest 'optimise_content' => sub {
	my %site = (HTTP_HOST => 'www.example.com', SERVER_NAME => 'www.example.com', NO_CACHE => 1);
	my $r = run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body><pre>a   b\n    c</pre>\n<textarea>x   y</textarea>\n",
			"<p>Hello</p>\n</body></html>";
	});
	like($r->{body}, qr{<pre>a   b\n    c</pre>}, '<pre> is left alone');
	like($r->{body}, qr{<textarea>x   y</textarea>}, '<textarea> is left alone');

	$r = run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body><p>Hello <b>a</b> <i>b</i></p></body></html>";
	});
	like($r->{body}, qr{Hello <b>a</b> <i>b</i>}, 'visible space between tags is kept');

	$r = run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body><script>var a = 1\n+ 2;</script></body></html>";
	});
	like($r->{body}, qr{\+ ?2}, '"+" at the start of a line is kept');

	$r = run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body><div>\n  <p class=\"intro\">\n  Hello</p>\n</div></body></html>";
	});
	like($r->{body}, qr{<div><p class="intro">Hello</p></div>}, 'whitespace around <p> with attributes is removed');

	$r = run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print qq{Content-Type: text/html\n\n<html><body><img border=0 src="http://www.example.com/a.png">},
			qq{<a class="x" href="http://www.example.com">home</a></body></html>};
	});
	like($r->{body}, qr{<img border=0 src="/a\.png">}, 'links in other attributes of <img> are shortened');
	like($r->{body}, qr{<a class="x" href="/">}, 'and of <a>');

	$r = run_script(init => 'optimise_content => 2', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body>",
			'<script type="text/javascript">document.write("a");</script>',
			'<p>between</p>',
			'<script type="text/javascript">document.write("b"); document.write("c");</script>',
			"</body></html>";
	});
	like($r->{body}, qr{<p>between</p>}, 'text between scripts is kept');
	like($r->{body}, qr{document\.write\("a"\)}, 'writes in different scripts are not merged');
	like($r->{body}, qr{document\.write\("b"\s*\+\s*"c"\)}, 'writes in the same script are merged');
	unlike($r->{body}, qr{text/JavaScript}, 'the script\'s type is not changed');

	my $start = time;
	run_script(init => 'optimise_content => 1', env => \%site, code => q{
		print "Content-Type: text/html\n\n<html><body>", '<title>' x 20000, '<a ' x 20000, ' ' x 20000, "</body></html>";
	});
	cmp_ok(time - $start, '<', 20, 'hostile input does not take quadratic time');
};

done_testing();
