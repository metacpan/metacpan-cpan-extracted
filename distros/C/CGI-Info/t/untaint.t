#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;

BEGIN {
	use_ok('CGI::Info');
}

SKIP: {
	eval { require CGI::Untaint; };
	skip 'CGI::Untaint required for testing compatability with CGI::Untaint', 5 if($@);
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&i=123';

	my $i = new_ok('CGI::Info');
	my %p = %{$i->params()};
	ok($p{i} == 123);
	ok($i->as_string() eq 'foo=bar;fred=wilma;i=123');

	my $u = CGI::Untaint->new(%p);

	ok($u->extract(-as_integer => 'i') == 123);
	ok($u->extract(-as_printable => 'foo') eq 'bar');
}
