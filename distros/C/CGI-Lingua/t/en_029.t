#!perl -Tw

use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
	require_ok('CGI::Lingua');
}

EN_029: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-029';
	$ENV{'REMOTE_ADDR'} = '201.229.32.134';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr', 'es-419'],
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Tests require Internet access', 4 unless(-e 't/online.enabled');
		ok(defined($l->country()));
		# Sometimes in aw sometimes in uy.  I guess the databases out
		# there aren't consistent
		ok(($l->country() eq 'aw') || ($l->country() eq 'uy'));
		ok($l->language_code_alpha2() eq 'en');
		ok($l->language() eq 'English');
	}
	ok(defined($l->requested_language()));
	TODO: {
		local $TODO = "sublanguage doesn't handle 3 characters";

		ok(defined($l->sublanguage()));
	};
}
