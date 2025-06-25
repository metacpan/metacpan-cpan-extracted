#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Info;
use Test::Most;

use lib 't/lib';
use MyLogger;

BEGIN { use_ok('CGI::Lingua') }

if(-e 't/online.enabled') {
	eval {
		CGI::Lingua->new();
	};
	ok($@ =~ m/You must give a list of supported languages/);

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
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined($l));
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'English');
	ok($l->requested_language() eq 'English');

	$l = CGI::Lingua->new(
		supported => ['en', 'fr', 'en-gb', 'en-us'],
		dont_use_ip => 1,
	);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok($l->requested_language() eq 'Unknown');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5';
	delete $ENV{'REMOTE_ADDR'};
	$l = CGI::Lingua->new(
		supported => ['en', 'fr', 'en-gb', 'en-us'],
		dont_use_ip => 1,
	);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United Kingdom');
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
	$l = CGI::Lingua->new(
		supported => ['en', 'fr', 'en-gb', 'en-us'],
		syslog => 1,
		logger => MyLogger->new()
	);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined($l->language_code_alpha2()));
	ok($l->language_code_alpha2() eq 'en');
	ok(!defined($l->sublanguage_code_alpha2()));
	if($l->language() ne 'English') {
		diag('Expected English got "' . $l->requested_language() . '"');
	}
	ok($l->name() eq 'English');
	ok(defined $l->requested_language());
	if($l->requested_language() !~ /English/) {
		diag('Expected English requested language, got "' . $l->requested_language() . '"');
	}
	ok($l->requested_language() =~ /English/);
	ok($l->country() eq 'gb');
	ok($l->locale()->code_alpha2() eq 'gb');

	delete($ENV{'REMOTE_ADDR'});
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'en');
	ok(!defined($l->sublanguage_code_alpha2()));
	ok(!defined($l->country()));

	# Ask for US English on a site serving only British English should still
	# say that English is the language
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'en');
	ok(!defined($l->sublanguage_code_alpha2()));
	ok(!defined($l->country()));

	# Ask for US English on a site serving British English and English
	# should say that English is the language
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-us';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb', 'fr']
	]);
	ok($l->language() eq 'English');
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English (United States)');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'en');
	ok(!defined($l->sublanguage_code_alpha2()));
	ok(!defined($l->country()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'no';
	$ENV{'REMOTE_ADDR'} = '212.125.194.122';
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok(defined($l->requested_language()));
	ok(!defined($l->language_code_alpha2()));
	ok(!defined($l->sublanguage_code_alpha2()));
	ok($l->country() eq 'no');
	if($l->country() ne 'no') {
		diag('Expected no got "' . $l->country() . '"');
	}
	ok($l->locale()->code_alpha2() eq 'no');

	delete($ENV{'HTTP_ACCEPT_LANGUAGE'});
	{
		local $ENV{'REMOTE_ADDR'} = 'a.b.c.d';
		$l = new_ok('CGI::Lingua' => [
			supported => ['en', 'fr']
		]);
		local $SIG{__WARN__} = sub { die $_[0] };
		throws_ok { $l->language() } qr/a\.b\.c\.d isn't a valid IP address/, 'Detects invalid IP address';
		ok(defined($l->requested_language()));
		ok($l->requested_language() eq 'Unknown');
		ok(!defined($l->language_code_alpha2()));
	}

	SKIP: {
		eval { require IP::Country; };
		skip 'IP::Country not installed', 2 if($@);

		$ENV{'REMOTE_ADDR'} = '255.255.255.255';
		my @messages;
		$l = new_ok('CGI::Lingua' => [
			supported => ['de', 'fr'],
			logger => \@messages
		]);
		ok($l->language() eq 'Unknown');
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-US,en;q=0.8';
	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
		# logger => sub {
			# my $params = $_[0];
			# diag($params->{'function'}, ': line ', $params->{'line'}, ': ', @{$params->{'message'}})
		# }
	]);
	ok(!defined($l->sublanguage_code_alpha2()));
	ok($l->language() eq 'English');
	cmp_ok($l->requested_language(), 'eq', 'English (United States)');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'en');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-ZZ,en;q=0.8';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'da', 'fr', 'nl', 'de', 'it', 'cy', 'pt', 'pl', 'ja' ],
		syslog => 1,
		# logger => sub {
			# my $params = $_[0];
			# diag($params->{'function'}, ': line ', $params->{'line'}, ': ', @{$params->{'message'}})
		# }
	]);
	ok($l->language() eq 'English');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'en');
	ok(!defined($l->sublanguage_code_alpha2()));
	cmp_ok($l->requested_language(), 'eq', 'English (Unknown: ZZ)');

	# Asking for French in the US should return French not English
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr';
	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok($l->language() eq 'French');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'fr');
	ok(!defined($l->sublanguage_code_alpha2()));
	cmp_ok($l->requested_language(), 'eq', 'French');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr-fr';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok($l->language() eq 'French');
	ok(!defined($l->sublanguage()));
	ok($l->language_code_alpha2() eq 'fr');
	ok(!defined($l->sublanguage_code_alpha2()));
	ok($l->requested_language() eq 'French (France)');

	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok($l->language() eq 'French');
	ok(defined($l->sublanguage()));
	ok($l->sublanguage() eq 'France');
	ok($l->language_code_alpha2() eq 'fr');
	ok(defined($l->sublanguage_code_alpha2()));
	ok($l->sublanguage_code_alpha2() eq 'fr');
	ok($l->requested_language() eq 'French (France)');

	# Everything says that we should deliver French, but it's not supported
	$ENV{'REMOTE_ADDR'} = '193.56.58.16';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok($l->language() eq 'Unknown');
	ok(!defined($l->sublanguage()));
	ok(!defined($l->language_code_alpha2()));
	ok(!defined($l->sublanguage_code_alpha2()));
	ok($l->requested_language() eq 'French');

	# Support only the Swiss version of French, but French French is requested, so give French with no
	#	version
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr-ch', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok($l->language() eq 'French');
	ok(!defined($l->sublanguage()));
	ok(defined($l->language_code_alpha2()));
	ok($l->language_code_alpha2() eq 'fr');
	ok(!defined($l->sublanguage_code_alpha2()));
	ok($l->requested_language() eq 'French (France)');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5,x-ns1Gcc7A8xaNx1,x-ns294eMxcVGQb2';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb' ]
	]);
	ok($l->language() eq 'English');
	ok($l->sublanguage() eq 'United Kingdom');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-zz';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb' ]
	]);
	ok($l->language() eq 'English');
	ok(!defined($l->sublanguage()));

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb';
	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-zz', 'de' ]
	]);
	ok($l->language() eq 'English');
	ok(!defined($l->sublanguage()));

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'lang=de';

	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-zz', 'de' ],
		info => new_ok('CGI::Info')
	]);
	ok($l->language() eq 'German');
	ok(!defined($l->sublanguage()));

	SKIP: {
		eval { require CHI; CHI->import(); };
		skip 'CHI not installed', 8 if($@);

		diag("Using CHI $CHI::VERSION");

		my $cache = CHI->new(driver => 'Memory', global => 1);

		$l = new_ok('CGI::Lingua' => [
			supported => [ 'en-zz', 'de' ],
			cache => $cache,
			info => new_ok('CGI::Info')
		]);
		ok($l->language() eq 'German');
		ok(!defined($l->sublanguage()));

		$l = undef;
		$l = new_ok('CGI::Lingua' => [
			supported => [ 'en-zz', 'de' ],
			cache => $cache,
			info => new_ok('CGI::Info')
		]);
		ok($l->language() eq 'German');
		ok(!defined($l->sublanguage()));
	}

	delete $ENV{'QUERY_STRING'};
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr,en-GB;q=0.9,en;q=0.8';

	$l = new_ok('CGI::Lingua' => [
		supported => [ 'en-gb', 'fr' ]
	]);
	cmp_ok($l->language(), 'eq', 'French', 'Check order of preference is honoured');
	is($l->sublanguage(), undef, 'No sublanguage has been requested');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en;q=0.5, ja;q=0.1';
	$l = new_ok('CGI::Lingua' => [{
		supported => ['ja', 'en'],
		syslog => 1,
		dont_use_ip => 1,
		logger => MyLogger->new()
	}]);
	cmp_ok($l->language(), 'eq', 'English', 'Checking quality value');
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en;q=0.1, ja;q=0.5';
	$l = new_ok('CGI::Lingua' => [{
		supported => ['ja', 'en'],
		syslog => 1,
		dont_use_ip => 1,
		logger => MyLogger->new()
	}]);
	cmp_ok($l->language(), 'eq', 'Japanese', 'Checking quality value');

	# Cover edge case: malformed Accept-Language headers
	subtest 'Malformed Accept-Language headers' => sub {
		my $test_cases = {
			'Empty language tag' => '";q=0.8,en;q=0.9"',
			'Invalid quality values' => 'en-US;q=1.1,es;q=-0.2,fr;q=abc',
			'Extra delimiters' => 'en,,es;q=0.8;;fr;q=0.5',
			'Missing q value' => 'en;q=,es;q=0.8;q=0.5',
			'Non-standard format' => 'lang=fr;q=0.8,language=en;q=0.7',
			'Unexpected characters' => 'en-US;q=0.9,@es;q=0.8,#fr;q=0.5',
			'Duplicated entries' => 'en-US,en-US;q=0.9,es;q=0.8',
			'Overly long header' => 'en;q=0.9,' . ('fr;q=0.8,' x 1000),
			'Mixed case and invalid' => 'EN-us;q=0.8,123;q=0.7,xx;q=0.6',
			'Empty header' => '',
		};

		foreach my $case (keys %$test_cases) {
			my $accept = $test_cases->{$case};
			local $ENV{'HTTP_ACCEPT_LANGUAGE'} = $accept;
			my $lingua = CGI::Lingua->new(
				supported_languages => [qw(en es fr)],
			);

			my $result = eval { $lingua->preferred_language() };
			ok(!$@, "No crash for case: $case");
			ok(defined($result));
			diag("Handled malformed header: $case ($accept)") if $@;
		}
	};
} else {
	diag('On-line tests disabled');
}

done_testing();
