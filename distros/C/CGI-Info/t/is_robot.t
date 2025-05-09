#!perl -w

use strict;
use warnings;

use Test::Most tests => 33;
use Data::Dumper;

use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Info');
}

ROBOT: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};

	my $cache;

	eval {
		require CHI;

		CHI->import;
	};
	if($@) {
		diag('CHI not installed');
		$cache = undef;
	} else {
		diag("Using CHI $CHI::VERSION");
		$cache = CHI->new(driver => 'RawMemory', global => 1);
		$cache->on_set_error('die');
		$cache->on_get_error('die');
	}

	my $i = new_ok('CGI::Info');
	ok($i->is_robot() == 0);

	$ENV{'REMOTE_ADDR'} = '65.52.110.76';
	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 0);

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)';
	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'REMOTE_ADDR'} = '119.63.196.107';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)';

	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 1);
	ok($i->browser_type() eq 'search');

	$ENV{'REMOTE_ADDR'} = '207.241.237.233';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; archive.org_bot +http://www.archive.org/details/archive.org_bot)';
	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 1);
	ok($i->browser_type() eq 'robot');

	$ENV{'REMOTE_ADDR'} = '82.94.176.140';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible;  Vagabondo/4.0; webcrawler at wise-guys dot nl; http://webagent.wise-guys.nl/; http://www.wise-guys.nl/)';
	$i = new_ok('CGI::Info' => [
		logger => MyLogger->new()
	]);
	ok($i->is_robot() == 1);
	ok($i->browser_type() eq 'robot');

	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.7; en-US; rv:1.9.2.20) Gecko/20110803 Firefox/3.6.20';
	$i = new_ok('CGI::Info' => [{
		cache => $cache,
	}]);
	$i->set_logger({ logger => MyLogger->new() });
	ok($i->is_robot() == 0);
	SKIP: {
		skip 'Test requires CHI access', 2 unless($cache);
		cmp_ok($cache->get("74.92.149.57/$ENV{HTTP_USER_AGENT}"), 'eq', 'unknown', 'cache sets unknown');
		ok(!defined($cache->get("74.92.149.58/$ENV{HTTP_USER_AGENT}")));
	}
	$ENV{'REMOTE_ADDR'} = '66.249.83.131';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Linux; Android 4.4.4; SAMSUNG-SGH-I337 Build/KTU84P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.89 Mobile Safari/537.36';
	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 0);

	$ENV{'HTTP_REFERER'} = 'http://free-video-tool.com';
	$i = new_ok('CGI::Info' => [
		cache => $cache,
	]);
	$i->set_logger(logger => MyLogger->new());
	ok($i->is_robot() == 1);
	SKIP: {
		skip 'Test requires CHI access', 2 unless($cache);
		cmp_ok($cache->get("66.249.83.131/$ENV{HTTP_USER_AGENT}"), 'eq', 'robot', 'cache sets robot');
		ok(!defined($cache->get("74.92.149.58/$ENV{HTTP_USER_AGENT}")));
	}

	$ENV{'HTTP_REFERER'} = 'http://0.tqn.com/d/d/spae.gif)';
	$i = new_ok('CGI::Info' => [
		cache => $cache,
	]);
	$i->set_logger(MyLogger->new());
	ok($i->is_robot() == 1);
	cmp_ok($i->status(), '==', 200, 'Default HTTP status is 200');

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; zh) AppleWebKit/522.11.3 (KHTML, like Gecko) Version/3.0 Safari/522.11.3\") OR EXTRACTVALUE(2534,CONCAT(0x5c,0x7170767871,(SELECT (ELT(2534=2534,1))),0x716b627171)) AND (\"OqXr\"=\"OqXr';
	delete $ENV{'HTTP_REFERER'};
	$i = new_ok('CGI::Info');
	ok($i->is_robot());
	cmp_ok($i->status(), '==', 403, 'Check HTTP_USER_AGENT SQL Injection is blocked');
}
