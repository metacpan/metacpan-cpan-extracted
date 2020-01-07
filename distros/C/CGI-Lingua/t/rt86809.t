#!perl -Tw

# Sometimes IANA reports 185.10.104.194 as being in NL rather than in Hong Kong

use strict;
use warnings;
use Test::Most;
# use Test::NoWarnings;	# Win32::locale::Lexicon produces warnings
use lib 't/lib';
use MyLogger;

eval 'use autodie qw(:all)';	# Test for open/close failures

# Work around for systems with broken Module::Load
# http://www.cpantesters.org/cpan/report/eae7b808-172d-11e0-a672-41e7f2486b6f
use Test::Requires {
	'Module::Load::Conditional' => 0.38
};

unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} else {
	plan tests => 8;

	use_ok('CGI::Lingua');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};

        $ENV{'REMOTE_ADDR'} = '185.10.104.194';

	my $l = CGI::Lingua->new({
		supported => ['en', 'fr', 'en-gb', 'en-us'],
		logger => MyLogger->new()
	});
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined($l->requested_language()));
	SKIP: {
		skip 'FIXME: find another China IP address', 4 if(defined($l->country()) && ($l->country() eq 'nl'));
		ok($l->requested_language() eq 'Chinese');
		ok(defined $l->language());
		ok($l->language() eq 'Unknown');
		ok($l->country() eq 'cn');
	}
}
