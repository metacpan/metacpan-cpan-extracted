#!perl -Tw

use strict;
use warnings;
use Test::Most;

if(-e 't/online.enabled') {
	plan tests => 48;

	use_ok('CGI::Lingua');
	require Test::NoWarnings;
	Test::NoWarnings->import();

	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	delete $ENV{'GEOIP_COUNTRY_CODE'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
        delete $ENV{'REMOTE_ADDR'};

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.19) Gecko/20110707 Firefox/3.6.19';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-us']
	]);
	ok(defined($l->locale()));
	ok(defined($l->locale()->currency()));
	ok($l->locale()->currency()->code() eq 'USD');

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	isa_ok($l->locale(), 'Locale::Object::Country');
	ok($l->locale()->currency()->code() eq 'GBP');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
	my @l = $l->locale()->languages_official();
	ok(uc($l[0]->code_alpha2()) eq 'EN');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');

        delete $ENV{'REMOTE_ADDR'};
	$ENV{'HTTP_USER_AGENT'} = 'Java';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-us']
	]);
	ok(!defined($l->locale()));

	# Asking for French in the US should return US locale
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr';
	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.7; en-US; rv:1.9.2.22) Gecko/20110902 Firefox/3.6.22';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok(defined($l->locale()));
	isa_ok($l->locale(), 'Locale::Object::Country');
	ok(uc($l->locale()->code_alpha2()) eq 'US');
	ok(defined($l->locale()->currency()));
	ok($l->locale()->currency()->code() eq 'USD');

	# User agent doesn't contain a location
	$ENV{'REMOTE_ADDR'} = '81.145.173.18';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.2; WOW64; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; MS-RTC LM 8; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb';

	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	isa_ok($l->locale(), 'Locale::Object::Country');
	ok($l->locale()->currency()->code() eq 'GBP');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
	@l = $l->locale()->languages_official();
	ok(uc($l[0]->code_alpha2()) eq 'EN');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');

	$ENV{'HTTP_USER_AGENT'} = 'foo';

	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	isa_ok($l->locale(), 'Locale::Object::Country');
	ok($l->locale()->currency()->code() eq 'GBP');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
	@l = $l->locale()->languages_official();
	ok(uc($l[0]->code_alpha2()) eq 'EN');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$ENV{'REMOTE_ADDR'} = '81.158.123.118';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.5 Safari/534.55.3';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
	]);
	my $locale = $l->locale();
	isa_ok($locale, 'Locale::Object::Country');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-ca';
	$ENV{'REMOTE_ADDR'} = '67.193.26.102';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; GTB7.3; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';

	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb' ]
	]);
	$locale = $l->locale();
	isa_ok($locale, 'Locale::Object::Country');
	ok(uc($l->locale()->code_alpha2()) eq 'CA');

	# LAN address
	$ENV{'REMOTE_ADDR'} = '192.168.1.2';

	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb' ]
	]);
	ok(!defined($l->locale()));

	# Find nothing
	delete $ENV{'REMOTE_ADDR'};
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
	]);
	$locale = $l->locale();
	ok(!defined($locale));

	# Add GEOIP_COUNTRY_CODE and now something should be found
	$ENV{'GEOIP_COUNTRY_CODE'} = 'GB';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
	]);
	$locale = $l->locale();
	isa_ok($locale, 'Locale::Object::Country');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
} else {
	plan skip_all => 'On-line tests disabled';
}
