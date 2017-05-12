#!perl -Tw

use strict;
use warnings;
use Test::More tests => 6;

# Fails with 190.24.1.122 - I think it has \r in the record

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

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'si';
	$ENV{'REMOTE_ADDR'} = '190.24.1.122';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
		ok(defined($l->country()));
		ok(defined($l->requested_language()));
	}
}
