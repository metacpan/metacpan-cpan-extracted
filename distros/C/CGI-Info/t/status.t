#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;
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
}
