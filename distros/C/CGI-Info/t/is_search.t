#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 27;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

SEARCH: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};

	my $cache;

	eval {
		require CHI;

		CHI->import;
	};

	if($@) {
		diag("CHI not installed");
		$cache = undef;
	} else {
		diag("Using CHI $CHI::VERSION");
		my $hash = {};
		$cache = CHI->new(driver => 'Memory', datastore => $hash);
	}

	my $i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 0);

	$ENV{'REMOTE_ADDR'} = '65.52.110.76';
	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 0);

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)';
	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'REMOTE_ADDR'} = '119.63.196.107';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)';

	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'REMOTE_ADDR'} = '207.241.237.233';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; archive.org_bot +http://www.archive.org/details/archive.org_bot)';

	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 0);

	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.7; en-US; rv:1.9.2.20) Gecko/20110803 Firefox/3.6.20';

	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 0);

	$ENV{'REMOTE_ADDR'} = '66.249.73.149';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';

	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'REMOTE_ADDR'} = '66.249.73.149';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; SeznamBot/3.2; +http://napoveda.seznam.cz/en/seznambot-intro/)';

	$i = new_ok('CGI::Info');
	ok($i->is_search_engine() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'HTTP_USER_AGENT'} = 'A nonsense user agent string';
	$ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$i = new_ok('CGI::Info' => [
		cache => $cache,
	]);
	ok($i->is_search_engine() == 0);
	ok($i->browser_type() eq 'robot');
diag($i->browser_type());
	SKIP: {
		skip 'Test requires CHI access', 2 unless($cache);
		ok(defined($cache->get("is_search/212.159.106.41/$ENV{HTTP_USER_AGENT}")));
		ok(!defined($cache->get("is_search/212.159.106.42/$ENV{HTTP_USER_AGENT}")));
	}
}
