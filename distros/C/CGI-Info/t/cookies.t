#!perl -w

use strict;
use warnings;
use Test::Most tests => 32;

BEGIN {
	use_ok('CGI::Info');
}

COOKIES: {
	my $i = new_ok('CGI::Info');

	ok(!defined($i->get_cookie(cookie_name => 'foo')));

	$ENV{'HTTP_COOKIE'} = 'foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok(!defined($i->get_cookie(cookie_name => 'bar')));
	diag('Ignore message about cookie_name argument not given');
	ok(!defined($i->get_cookie(cookie_name => undef)));

	$ENV{'HTTP_COOKIE'} = 'fred=wilma; foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok($i->get_cookie('fred') eq 'wilma');
	ok($i->cookie('fred') eq 'wilma');
	ok($i->get_cookie({cookie_name => 'fred'}) eq 'wilma');
	ok(!defined($i->get_cookie(cookie_name => 'bar')));
	ok(!defined($i->get_cookie({cookie_name => 'bar'})));
	ok(!defined($i->get_cookie({cookie_name => undef})));

	local $SIG{__WARN__} = sub { die $_[0] };
	eval {
		$i->get_cookie();
	};
	ok($@ =~ /^Usage: /);

	$ENV{'HTTP_COOKIE'} = 'phpbb3_ljj67_k=3dba1f0d50e51f76; style_cookie=printonly; __utma=249501332.293603655.1368565227.1380805951.1380808408.13; __utmz=249501332.1368565227.1.1.utmccn=(direct)|utmcsr=(direct)|utmcmd=(none); phpbb3_ljj67_u=2; phpbb3_ljj67_sid=51f2e6172a078b85e79cf95a5c930c18; __utmc=249501332; cart=tubabb:1';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'cart') eq 'tubabb:1');
	ok($i->cookie('cart') eq 'tubabb:1');
}

# Cookie not set, should warn about missing field
{
	local $ENV{'HTTP_COOKIE'} = 'user=JohnDoe; session=abc123';  # Example cookie
	my $obj = new_ok('CGI::Info');

	# Check for missing field
	diag('Ignore message about what cookie would you like');
	is($obj->cookie(), undef, 'undef if no cookie field is provided');
}

# Cookie jar is populated correctly with valid cookies
{
	local $ENV{'HTTP_COOKIE'} = 'user=JohnDoe; session=abc123';  # Example cookie
	my $obj = new_ok('CGI::Info');

	# Test retrieving cookies from jar
	is($obj->cookie('user'), 'JohnDoe', 'Correctly retrieves "user" cookie');
	is($obj->cookie('session'), 'abc123', 'Correctly retrieves "session" cookie');
}

# Cookie field not found in the jar
{
	local $ENV{'HTTP_COOKIE'} = 'user=JohnDoe; session=abc123';  # Example cookie
	my $obj = new_ok('CGI::Info');

	# Test non-existent cookie field
	is($obj->cookie('nonexistent'), undef, 'Returns undef for non-existent cookie');
}

# Cookie field provided but no cookies in the header (edge case)
{
	local $ENV{'HTTP_COOKIE'} = '';  # No cookies set
	my $obj = new_ok('CGI::Info');

	# Test with no cookies available
	is($obj->cookie('user'), undef, 'Returns undef when no cookies are available');
}

# Ensure loading of the cookie jar
{
	local $ENV{'HTTP_COOKIE'} = 'user=JaneDoe; theme=dark';  # Example cookie
	my $obj = new_ok('CGI::Info');

	# Test loading of the cookie jar
	is($obj->cookie('user'), 'JaneDoe', 'Loads cookies and retrieves "user" cookie');
	is($obj->cookie('theme'), 'dark', 'Loads cookies and retrieves "theme" cookie');
}
