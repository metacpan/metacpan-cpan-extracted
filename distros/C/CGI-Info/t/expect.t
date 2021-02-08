#!perl -wT

use strict;
use warnings;
use Test::Most tests => 14;
use Test::NoWarnings;
use Test::Warn;

BEGIN {
	use_ok('CGI::Info');
}

PARAMS: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	my @expect = ('fred');
	my $i = new_ok('CGI::Info');
	my %p = %{$i->params({expect => \@expect})};
	ok(!exists($p{foo}));
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	@expect = ('foo');
	$i = new_ok('CGI::Info' => [
		expect => \@expect
	]);
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');
	ok(!exists($p{fred}));
	ok($i->as_string() eq 'foo=bar,baz');

	# Reading twice should yield the same result
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');

	warning_is {
		my $foo = CGI::Info->new(expect => 'scalar');
	} 'expect must be a reference to an array';

	warning_is {
		my $foo = new_ok('CGI::Info')->params(expect => 'scalar');
	} 'expect must be a reference to an array';
}
