#!perl -wT

use strict;
use warnings;
use Test::Most tests => 20;

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
	ok($@ =~ /cookie_name argument not given/);

	$ENV{'HTTP_COOKIE'} = 'phpbb3_ljj67_k=3dba1f0d50e51f76; style_cookie=printonly; __utma=249501332.293603655.1368565227.1380805951.1380808408.13; __utmz=249501332.1368565227.1.1.utmccn=(direct)|utmcsr=(direct)|utmcmd=(none); phpbb3_ljj67_u=2; phpbb3_ljj67_sid=51f2e6172a078b85e79cf95a5c930c18; __utmc=249501332; cart=tubabb:1';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'cart') eq 'tubabb:1');
	ok($i->cookie('cart') eq 'tubabb:1');
}
