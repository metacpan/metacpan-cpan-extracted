#!perl -Tw

use strict;
use warnings;
use Test::More tests => 55;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Lingua');
}

USGB: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

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
		$cache = CHI->new(driver => 'Memory', global => 1);
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-GB,en-US;q=0.8,en;q=0.6';
	$ENV{'REMOTE_ADDR'} = '95.147.222.177';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja'],
		cache => $cache
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United Kingdom');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-GB';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja'],
		cache => $cache
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United Kingdom');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-US';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-us', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja'],
		cache => $cache
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United States');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja'],
		cache => $cache
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United Kingdom');

	$l = $l->new(
		supported => ['en', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja'],
		cache => $cache
	);
	ok(defined $l);
	isa_ok($l, 'CGI::Lingua');
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English');
	ok($l->language() eq 'English');
	ok(!defined($l->sublanguage()));

	# We want US English, but only Britsh English is served, return English
	# but with no sublanguage support
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb'],
		cache => $cache
	]);
	ok(defined $l);
	isa_ok($l, 'CGI::Lingua');
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
		ok($l->locale()->code_alpha2() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok($l->language() eq 'English');
	ok(!defined($l->sublanguage()));
}
