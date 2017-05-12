#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 52;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Lingua');
}

LANGUAGES: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

        delete($ENV{'REMOTE_ADDR'});

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(!defined($l->sublanguage()));
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(!defined($l->sublanguage()));
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-us', 'fr', 'en-gb']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(defined($l->sublanguage()));
	ok($l->sublanguage() eq 'United States');
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'fr', 'en-us']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(defined($l->sublanguage()));
	ok($l->sublanguage() eq 'United States');
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United Kingdom)');
	ok($l->sublanguage() eq 'United Kingdom');
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->sublanguage() eq 'United Kingdom');	# Check sublanguage first
	ok($l->requested_language() eq 'English (United Kingdom)');
	ok($l->language() eq 'English');
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English');
	ok(!defined($l->sublanguage()));
	ok($l->code_alpha2() eq 'en');
	ok(!defined($l->country()));
}
