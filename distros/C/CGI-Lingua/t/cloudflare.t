#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 19;

BEGIN {
	require_ok('CGI::Lingua');
}

CLOUDFLARE: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-GB,en-US;q=0.8,en;q=0.6';
	$ENV{'REMOTE_ADDR'} = '95.147.222.177';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	$ENV{'HTTP_CF_IPCOUNTRY'} = 'GB';
	ok($l->country() eq 'gb');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');

	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	$ENV{'HTTP_CF_IPCOUNTRY'} = 'FR';
	ok($l->country() eq 'fr');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');

	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	$ENV{'HTTP_CF_IPCOUNTRY'} = 'XX';
	SKIP: {
		skip 'Test requires Internet access', 1 unless(-e 't/online.enabled');
		ok($l->country() eq 'gb');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');
}
