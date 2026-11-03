#!perl -w

# Security regressions: responses and requests that mustn't be shared between
# clients through the server-side cache

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Most;
use Test::Needs 'CHI';
use Test::CGIBuffer qw(run_script second_request header);

my $html = '<html><head><title>t</title></head><body>hello</body></html>';

# Was the response to the second request generated afresh?
sub not_stored {
	my ($result, $name) = @_;

	like((header($result, 'X-Cache-Lookup'))[0], qr/^MISS/, $name);
}

subtest 'Set-Cookie is not replayed to other clients' => sub {
	my $r = second_request(
		cache => 1,
		code => qq{print "Content-Type: text/html\\n", (\$ENV{FIRST} ? "Set-Cookie: session=SECRET\\n" : ''), "\\n$html";}
	);
	unlike($r->{output}, qr/SECRET/, 'cookie not sent to the second client');
	not_stored($r, 'response was not stored');
	like((header($r, 'X-Cache'))[0], qr/^MISS/, 'X-Cache says that the page was generated');
};

foreach my $control('no-store', 'no-cache', 'private', 'Private, max-age=60') {
	subtest "Response Cache-Control: $control is not stored" => sub {
		not_stored(second_request(cache => 1, code => qq{print "Content-Type: text/html\\nCache-Control: $control\\n\\n$html";}),
			'response was not stored');
	};
}

subtest 'Vary on a request header is not stored' => sub {
	not_stored(second_request(cache => 1, code => qq{print "Content-Type: text/html\\nVary: User-Agent\\n\\n$html";}),
		'response was not stored');
};

subtest 'Vary: Accept-Encoding is stored' => sub {
	my $r = second_request(cache => 1, code => qq{print "Content-Type: text/html\\nVary: Accept-Encoding\\n\\n$html";});
	like((header($r, 'X-Cache-Lookup'))[0], qr/^HIT/, 'response was stored');
	like((header($r, 'X-Cache'))[0], qr/^HIT/, 'X-Cache says that the page came from the cache');
};

subtest 'A page containing the client\'s csrf_token is not stored' => sub {
	not_stored(second_request(
		cache => 1,
		env => { HTTP_COOKIE => 'csrf_token=abc%2B123' },
		code => q{print "Content-Type: text/html\n\n<html><body><input value=\"abc+123\"></body></html>";}
	), 'response was not stored');
};

subtest 'A partial HTML page is not stored' => sub {
	not_stored(second_request(cache => 1, code => q{print "Content-Type: text/html\n\n<html><body>half";}),
		'response was not stored');
};

my $can_cache = q{print "Content-Type: text/plain\n\n", (CGI::Buffer::can_cache() ? 'yes' : 'no');};

foreach my $env(
	{ REQUEST_METHOD => 'POST' },
	{ HTTP_AUTHORIZATION => 'Basic dXNlcjpwYXNz' },
	{ REMOTE_USER => 'alice' },
	{ HTTP_CACHE_CONTROL => 'max-age=0' },
	{ HTTP_CACHE_CONTROL => 'No-Cache, max-age=10' },
	{ NO_CACHE => 1 },
) {
	my ($name) = keys %{$env};
	subtest "can_cache is false with $name=$env->{$name}" => sub {
		is(run_script(env => $env, code => $can_cache)->{body}, 'no', 'cache not used');
	};
}

subtest 'can_cache is true for a plain GET' => sub {
	is(run_script(code => $can_cache)->{body}, 'yes', 'cache used');
};

subtest 'Client max-age is limited' => sub {
	foreach my $test(['max-age=60', '60 seconds'], ['max-age=99999999', 'default'], ['max-age=1abc', 'default']) {
		my ($control, $expect) = @{$test};
		my $r = run_script(
			env => { HTTP_CACHE_CONTROL => $control },
			code => q{
				use CHI;
				CGI::Buffer::init(cache => CHI->new(driver => 'Memory', global => 1));
				print "Content-Type: text/plain\n\n", ($CGI::Buffer::cache_duration // 'default');
			}
		);
		is($r->{body}, $expect, "$control gives $expect");
	}
};

subtest 'Generated cache key' => sub {
	my $r = run_script(
		env => { HTTP_COOKIE => 'a=1; __utma=2; __utmz=3; csrf_token=4; b=5', PATH_INFO => '/foo' },
		code => q{
			use CHI;
			CGI::Buffer::init(cache => CHI->new(driver => 'Memory', global => 1));
			print "Content-Type: text/plain\n\n", CGI::Buffer::_generate_key();
		}
	);
	like($r->{body}, qr/::a=1/, 'first cookie in key');
	like($r->{body}, qr/::b=5/, 'later cookie in key');
	unlike($r->{body}, qr/__utm/, 'Google Analytics cookies not in key');
	unlike($r->{body}, qr/csrf_token/, 'csrf_token not in key');
	like($r->{body}, qr/PATH_INFO=::foo/, 'PATH_INFO in key');
};

subtest 'optimise_content does not make other sites local' => sub {
	my $r = run_script(
		init => 'optimise_content => 1',
		env => { HTTP_HOST => 'www.example.com', SERVER_NAME => 'www.example.com', NO_CACHE => 1 },
		code => q{print qq{Content-Type: text/html\n\n<html><body><a href="http://www.example.com.evil.org/x">e</a> <a href="http://www.example.com/y">l</a></body></html>};}
	);
	like($r->{body}, qr{href="http://www\.example\.com\.evil\.org/x"}, 'other site left alone');
	like($r->{body}, qr{href="/y"}, 'own site made local');
};

done_testing();
