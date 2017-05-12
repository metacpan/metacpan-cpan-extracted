#!perl -Tw

use strict;
use warnings;
use Test::More tests => 6;

# See https://rt.cpan.org/Public/Bug/Display.html?id=77332

BEGIN {
	use_ok('CGI::Lingua');
}

RT77332: {
	diag('Ignore messages about the non existant Byelorussian language. See https://rt.cpan.org/Public/Bug/Display.html?id=77332');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 6.0; MSIE 5.5; Windows NT 5.0) Opera 7.02 Bork-edition [en]';
	$ENV{'REMOTE_ADDR'} = '178.125.86.23';
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};

	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));

	TODO: {
		local $TODO = 'https://rt.cpan.org/Public/Bug/Display.html?id=77332';
		SKIP: {
			skip 'Test requires Internet access', 2 unless(-e 't/online.enabled');
			ok(defined($l->code_alpha2()));
			ok($l->country() eq 'by');
		}
	};
}
