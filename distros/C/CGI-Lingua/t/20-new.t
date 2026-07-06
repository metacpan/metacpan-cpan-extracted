#!perl -Tw

use strict;
use warnings;

use Test::Most tests => 33;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Lingua');
}

LANGUAGES: {
	eval {
		CGI::Lingua->new();
	};
	ok($@ =~ m/^Usage:/);

	eval {
		CGI::Lingua::new();
	};
	ok($@ =~ m/^Usage:/);

	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
        delete $ENV{'REMOTE_ADDR'};
	my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok($l->requested_language() eq 'Unknown');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = '';
        $ENV{'REMOTE_ADDR'} = '66.249.67.232';	# Google
	$l = CGI::Lingua->new({supported_languages => ['en', 'fr', 'en-gb', 'en-us']});
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Tests require Internet access', 2 unless(-e 't/online.enabled');
		ok($l->language() eq 'English');
		ok($l->requested_language() eq 'English');
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5';
        delete $ENV{'REMOTE_ADDR'};
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'English');
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'English (United Kingdom)');

	$l = CGI::Lingua->new(supported => ['de', 'fr']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok(defined $l->requested_language());
	if($l->requested_language() ne 'Unknown') {
		diag('Expected Unknown got "' . $l->requested_language() . '"');
	}
	ok($l->requested_language() eq 'Unknown');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'zz';
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok(defined $l->requested_language());

        $ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$l = CGI::Lingua->new({
		supported => ['en', 'fr', 'en-gb', 'en-us'],
		logger => MyLogger->new()
	});
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Tests require Internet access', 6 unless(-e 't/online.enabled');
		ok($l->name() eq 'English');
		ok(defined($l->code_alpha2()));
		ok($l->code_alpha2() eq 'en');

		ok(defined $l->requested_language());
		ok($l->requested_language() =~ /English/);
		ok($l->country() eq 'gb');
	}
}
