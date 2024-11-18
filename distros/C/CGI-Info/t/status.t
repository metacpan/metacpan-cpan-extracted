#!perl -w

use strict;
use warnings;
use Test::Most tests => 25;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

STATUS: {
	local %ENV;

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

	$ENV{'REQUEST_METHOD'} = 'OPTIONS';
	cmp_ok(new_ok('CGI::Info')->status(), '==', 405, "Notify that OPTIONS isn't suported");
}

# Basic tests
{
	# Instantiate object
	my $obj = new_ok('CGI::Info');

	# Test setting and retrieving a status
	is($obj->status(404), 404, 'Setting status to 404');
	is($obj->status, 404, 'Retrieving previously set status 404');

	# Test without setting status (default 200)
	$obj = new_ok('CGI::Info');
	cmp_ok($obj->status, '==', 200, 'Default status 200 when no status is set');
}

# Test when REQUEST_METHOD is OPTIONS (expect 405)
{
	local $ENV{'REQUEST_METHOD'} = 'OPTIONS';

	my $obj = new_ok('CGI::Info');
	is($obj->status, 405, 'OPTIONS request returns status 405');
}

# Test when REQUEST_METHOD is DELETE (expect 405)
{
	local $ENV{'REQUEST_METHOD'} = 'DELETE';

	my $obj = new_ok('CGI::Info');
	is($obj->status, 405, 'DELETE request returns status 405');
}

# Test POST without CONTENT_LENGTH (expect 411)
{
	local $ENV{'REQUEST_METHOD'} = 'POST';
	local $ENV{'CONTENT_LENGTH'} = undef;

	my $obj = new_ok('CGI::Info');
	is($obj->status, 411, 'POST without CONTENT_LENGTH returns status 411');
}

# Test POST with CONTENT_LENGTH (expect 200 as default)
{
	local $ENV{'REQUEST_METHOD'} = 'POST';
	local $ENV{'CONTENT_LENGTH'} = 100;

	my $obj = new_ok('CGI::Info');
	is($obj->status, 200, 'POST with CONTENT_LENGTH returns status 200');
}
