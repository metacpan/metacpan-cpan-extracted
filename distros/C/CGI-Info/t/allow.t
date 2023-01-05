#!perl -wT

use strict;
use warnings;
use Test::Most tests => 37;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

ALLOWED: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	my %allowed = ('fred' => undef);
	my $i = new_ok('CGI::Info');
	my %p = %{$i->params({allow => \%allowed})};
	ok(!exists($p{foo}));
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'fred=wilma');

	$ENV{'QUERY_STRING'} = 'barney=betty&fred=wilma';
	%allowed = ('fred' => 'barney', 'wilma' => 'betty');
	$i = new_ok('CGI::Info');
	is($i->params({allow => \%allowed}), undef, 'Check when different parameter is given');
	cmp_ok($p{fred}, 'eq', 'wilma', 'check valid param');
	cmp_ok($i->as_string(), 'eq', '', 'no valid args gives empty as_string()');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	%allowed = ('foo' => undef);
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');
	ok(!exists($p{fred}));
	ok($i->as_string() eq 'foo=bar,baz');

	# Reading twice should yield the same result
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');

	%allowed = ('foo' => qr(\d+));
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	ok(!defined($i->params()));
	ok($i->as_string() eq '');
	local $SIG{__WARN__} = sub { die $_[0] };
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);

	$ENV{'QUERY_STRING'} = 'foo=123&fred=wilma';

	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	%p = %{$i->params()};
	ok($p{foo} eq '123');
	ok(!exists($p{fred}));
	ok($i->param('foo') eq '123');
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);
	ok($i->as_string() eq 'foo=123');

	#---------------------
	# What if the allowed parameters become more restrictive, that can
	#	happen when a client did a peek then sets the allowed

	$ENV{'QUERY_STRING'} = 'foo=123&fred=wilma&admin=1';
	$i = new_ok('CGI::Info');
	ok($i->param('fred') eq 'wilma');
	ok($i->param('admin') == 1);
	%p = %{$i->params(allow => \%allowed)};
	ok($p{foo} eq '123');
	ok(!exists($p{fred}));
	ok(!exists($p{'admin'}));
	eval { $i->param('admin') };
	ok($@ =~ /admin isn't in the allow list at/);
	ok($i->param('foo') eq '123');
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);
	ok($i->as_string() eq 'foo=123');

	%allowed = ('foo' => qr([a-z]+));
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	ok(!defined($i->params()));
}
