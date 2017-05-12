#!perl -Tw

use strict;
use warnings;
use Test::More tests => 8;

# See https://rt.cpan.org/Public/Bug/Display.html?id=79214

BEGIN {
	use_ok('CGI::Lingua');
}

RT79214: {
	diag('Ignore messages about Can\'t determine language from IP 24.50.196.23. See https://rt.cpan.org/Public/Bug/Display.html?id=79214');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'REMOTE_ADDR'} = '24.50.196.23';
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
	my $l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'nl', 'da', 'fr', 'de', 'pl' ]
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 4 unless(-e 't/online.enabled');
		ok($l->country() eq 'pr');
		ok(defined($l->requested_language()));
		ok($l->language() eq 'Unknown');

		TODO: {
			local $TODO = 'https://rt.cpan.org/Public/Bug/Display.html?id=79214';
			ok(!defined($l->code_alpha2()));
		};
	}
}
