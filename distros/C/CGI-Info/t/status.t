#!perl -wT

use strict;
use warnings;
use Test::Most tests => 10;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

PARAMS: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = new_ok('CGI::Info');

	ok($i->status() == 200);
	ok($i->status(418) == 418);
	ok($i->status() == 418);

	$ENV{'REQUEST_METHOD'} = 'DELETE';
	is(new_ok('CGI::Info')->status(), 405, "Notify that DELETE isn't supported");

	$ENV{'REQUEST_METHOD'} = 'POST';
	is(new_ok('CGI::Info')->status(), 411, 'Notify that CONTENT_LENGTH is needed for POST');
}
