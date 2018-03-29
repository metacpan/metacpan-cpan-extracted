#!perl -wT

use strict;
use warnings;
use Test::Most tests => 28;
use Test::NoWarnings;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Info');
}

PARAM: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar');
	ok(!defined($i->param('fred')));
	ok($i->as_string() eq 'foo=bar');

	$ENV{'QUERY_STRING'} = '=bar';

	$i = new_ok('CGI::Info');
	ok(!defined($i->param('fred')));
	ok($i->as_string() eq '');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';

	$i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	$i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar,baz');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar,baz;fred=wilma');

	# Reading twice should yield the same result
	ok($i->param('foo') eq 'bar,baz');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma';
	$i = new_ok('CGI::Info');
	my %p = %{$i->param()};
	ok(!defined($i->param('foo')));
	ok($i->as_string() eq 'fred=wilma');

	# Don't pass XSS through
	$ENV{'QUERY_STRING'} = 'foo=<script>alert(hello)</script>';
	$i = new_ok('CGI::Info');
	ok(defined($i->param('foo')));
	ok($i->as_string() eq 'foo=&lt\;script&gt\;alert(hello)&lt\;/script&gt\;');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma&foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->param('foo', logger => MyLogger->new()) eq 'bar');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');
}
