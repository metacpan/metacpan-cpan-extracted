#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 30;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

MOBILE: {
        delete $ENV{'HTTP_X_WAP_PROFILE'};
	delete $ENV{'HTTP_USER_AGENT'};

	my $i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);

	$ENV{'HTTP_X_WAP_PROFILE'} = 'http://www.blackberry.net/go/mobile/profiles/uaprof/9000_80211g/5.0.0.rdf';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);
	ok($i->browser_type eq 'mobile');

        delete $ENV{'HTTP_X_WAP_PROFILE'};
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (iPhone; U)';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);
	ok($i->browser_type eq 'mobile');

	$ENV{'HTTP_USER_AGENT'} = 'HTTP_USER_AGENT=BlackBerry9000/5.0.0.681 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/142';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);
	ok($i->browser_type eq 'mobile');

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.18) Gecko/20110614 Firefox/3.6.18';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);
	ok($i->browser_type eq 'web');

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (iPad; CPU OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);
	ok($i->browser_type eq 'mobile');

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Linux; U; Android 2.3.4; en-gb; SonyEricssonLT18i Build/4.0.2.A.0.62) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';
	$i = $i->new();
	isa_ok($i, 'CGI::Info');
	ok($i->is_mobile() == 1);
	ok($i->browser_type eq 'mobile');

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Linux; Android 4.2.2; SAMSUNG-SGH-I337 Build/JDQ39) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.59 Mobile Safari/537.36';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile());
	ok(!$i->is_search_engine());
	ok(!$i->is_robot());
	ok($i->browser_type eq 'mobile');

	$ENV{'HTTP_USER_AGENT'} = 'A nonsense user agent string';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);
	ok($i->browser_type ne 'mobile');
}
