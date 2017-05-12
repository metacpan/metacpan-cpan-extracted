#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch::Regexp;

use Test::Deep;
use Test::More;

# ------------------------------------------------
# See also CGI::Snapp's t/psgi.basic.pl.
# This demo is copied from CGI::Application V 4.50 t/run_as_psgi.t.
# The PATH_INFO translates to t/lib/CGI::Snapp::Dispatch::PSGITest.

sub test_1
{
	my($env) =
	{
		REQUEST_METHOD  => 'GET',
		QUERY_STRING    => 'game=chess&game=checkers&weather=dull',
		PATH_INFO       => '/CGI_snapp_dispatch_PSGITest',
		PATH_TRANSLATED => '/usr/local/somewhere/else',
		SCRIPT_NAME     => '/cgi-bin/foo.cgi',
		SERVER_PROTOCOL => 'HTTP/1.0',
		SERVER_PORT     => 8080,
		SERVER_NAME     => 'the.good.ship.lollypop.com',
		HTTP_LOVE       => 'true',
	};

	$$env{REQUEST_URI} = "$$env{SCRIPT_NAME}$$env{PATH_INFO}?$$env{QUERY_STRING}";
	my($psgi)          = CGI::Snapp::Dispatch::Regexp -> new -> as_psgi;

	ok(ref $psgi eq 'CODE', 'as_psgi() returns a coderef');

	my($output) = $psgi -> ($env);

	cmp_deeply
	(
	$output,
	[
		200,
		[
			"Content-Type",
			"text/html; charset=ISO-8859-1"
		],
		[
			"Hello World"
		]
	],
	'CGI::Snapp::Dispatch::Regexp works with as_psgi()',
	);

	return 2;

} # End of test_1.

# ------------------------------------------------

my($count) = 0;

$count += test_1;

done_testing($count);
