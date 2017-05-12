#!perl -Tw

use strict;
use warnings;
use Test::More tests => 8;

# See https://rt.cpan.org/Public/Bug/Display.html?id=69509

BEGIN {
	use_ok('CGI::Lingua');
}

RT69509: {
	diag('Ignore messages about the Singhalese language. See https://rt.cpan.org/Public/Bug/Display.html?id=69509');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'si';
	$ENV{'REMOTE_ADDR'} = '203.143.14.232';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 4 unless(-e 't/online.enabled');
		ok($l->country() eq 'lk');
		ok(defined($l->requested_language()));

		TODO: {
			local $TODO = 'https://rt.cpan.org/Public/Bug/Display.html?id=69509';

			ok($l->language() eq 'Unknown');
			ok(!defined($l->code_alpha2()));
		};
	}
}
