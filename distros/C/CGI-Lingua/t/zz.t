#!perl -Tw

use strict;
use warnings;
use Test::Most;

eval 'use autodie qw(:all)';	# Test for open/close failures

# Test records where Locale::Object::Country->new() fails

unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} else {
	plan tests => 9;

	use_ok('CGI::Lingua');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36';

	$ENV{'REMOTE_ADDR'} = '45.56.96.183';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en']
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));

	SKIP: {
		skip 'Tests require Internet access', 4 unless(-e 't/online.enabled');
		diag('Ignore "is not known" message');
		ok(defined($l->country()));
		if($l->country() eq 'zz') {
			# Depends on your set-up
			ok(!defined($l->language_code_alpha2()));
			ok($l->language() eq 'Unknown');
			ok($l->requested_language() eq 'Unknown');
		} else {
			ok($l->language_code_alpha2() eq 'en');
			ok($l->language() eq 'English');
			ok($l->requested_language() eq 'English');
		}
	}
	ok(!defined($l->sublanguage()));
	# diag($l->locale());
}
