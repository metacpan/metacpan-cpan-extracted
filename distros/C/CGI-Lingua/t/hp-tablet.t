#!perl -Tw

use strict;
use warnings;
use Test::More tests => 7;

# See https://github.com/oalders/http-browserdetect/issues/36

BEGIN {
	use_ok('CGI::Lingua');
}

RT77332: {
	diag('Ignore messages about the unknown country ta. See https://github.com/oalders/http-browserdetect/issues/36');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-nz,en;q=0.5';
	$ENV{'REMOTE_ADDR'} = '121.72.152.78';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (hp-tablet; Linux; hpwOS/3.0.2; U; en-NZ) AppleWebKit/534.6 (KHTML, like Gecko) wOSBrowser/234.40.1 Safari/534.6 TouchPad/1.0';
	my $l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));

	TODO: {
		local $TODO = 'https://github.com/oalders/http-browserdetect/issues/36';
		ok(defined($l->code_alpha2()));
		isa_ok($l->locale(), 'Locale::Object::Country');
		SKIP: {
			skip 'Test requires Internet access', 1 unless(-e 't/online.enabled');
			ok(uc($l->locale()->code_alpha2()) eq 'NZ');
		}
	};
}
