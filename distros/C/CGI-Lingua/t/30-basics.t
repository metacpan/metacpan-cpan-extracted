#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw/tempfile/;
use Test::Most;
use Test::Needs 'CHI', 'IP::Country', 'Test::LWP::UserAgent', 'Test::MockModule';
use Test::Without::Module qw(Geo::IP);

BEGIN { use_ok('CGI::Lingua') }

# Setup: Mock environment and dependencies
my $mock_env = {
	'HTTP_ACCEPT_LANGUAGE' => 'en-US,en;q=0.9',
	'REMOTE_ADDR' => '123.45.67.89',
	'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64)',
};

my $cache = CHI->new(driver => 'Memory', global => 1);

# Mock IP geolocation responses
my $mock_ip_country = Test::MockModule->new('IP::Country::Fast');
$mock_ip_country->mock('inet_atocc', sub { 'US' });

my $mock_lwp_simple = Test::MockModule->new('LWP::Simple::WithCache');
$mock_lwp_simple->mock('get', sub { '{ "timezone": "America/New_York" }' });

# Basic language detection
subtest 'Language Detection' => sub {
	local %ENV = %{$mock_env};

	my $lingua = CGI::Lingua->new(
		supported => ['en', 'fr'],
		cache => $cache,
	);

	is($lingua->language(), 'English', 'Correct language from Accept-Language header');
	is($lingua->code_alpha2(), 'en', 'Valid 2-letter language code');
};

# Country detection via IP
subtest 'Country Resolution' => sub {
	local %ENV = %{$mock_env};

	my $lingua = CGI::Lingua->new(
		supported => 'en',
		cache => $cache,
	);

	is($lingua->country(), 'us', 'Country code from mocked IP::Country');
	ok($cache->get('CGI::Lingua:country:123.45.67.89'), 'Country result cached');
};

# Fallback to IP when no Accept-Language
subtest 'No Language Header' => sub {
	local %ENV = %{$mock_env};
	delete $ENV{HTTP_ACCEPT_LANGUAGE};

	my $lingua = CGI::Lingua->new(
		supported => ['en'],
		cache => $cache,
	);

	is($lingua->language(), 'English', 'Language resolved via IP country (US)');
};

# Edge case - Loopback IP
subtest 'Localhost IP' => sub {
	local %ENV = %{$mock_env};
	$ENV{REMOTE_ADDR} = '127.0.0.1';

	my $lingua = CGI::Lingua->new(
		supported => ['en'],
		cache => $cache,
	);

	ok(!defined $lingua->country(), 'No country for localhost IP');
};

# Time zone detection
subtest 'Time Zone' => sub {
	if(-e 't/online.enabled') {	# Fix http://www.cpantesters.org/cpan/report/cf983ce4-17db-11f0-894c-9c582d706e6a
		local %ENV = %{$mock_env};

		my $lingua = CGI::Lingua->new(
			supported => ['en'],
			cache => $cache,
		);

		is($lingua->time_zone(), 'America/New_York', 'Time zone from ip-api.com');
	}
};

# Unsupported languages
subtest 'Unsupported Language' => sub {
	local %ENV = %{$mock_env};

	my $lingua = CGI::Lingua->new(
		supported => ['fr'],
		cache => $cache,
	);

	is($lingua->language(), 'Unknown', 'No supported languages match request');
	like($lingua->requested_language(), qr/English/, 'Shows requested language');
};

subtest 'Locale Detection' => sub {
	my $mock_country = Test::MockModule->new('Locale::Object::Country');
	$mock_country->mock('name', sub { 'MockCountry' });
	$mock_country->mock('code_alpha2', sub { 'MC' });

	# Locale from Locale::Object::Country
	subtest 'From User-Agent' => sub {
		local %ENV = (
			%{$mock_env},
			HTTP_USER_AGENT => 'Mozilla/5.0 (X11; Linux x86_64; rv:91.0) en-US'
		);

		my $lingua = CGI::Lingua->new(supported => ['en']);
		my $locale = $lingua->locale();
		isa_ok($locale, 'Locale::Object::Country', 'Locale object');
		is($locale->code_alpha2(), 'MC', 'Correct country from Locale::Object::Country');
	};

	# Invalid country code
	subtest 'Invalid Code' => sub {
		local %ENV = %{$mock_env};
		$ENV{GEOIP_COUNTRY_CODE} = 'XX';

		# Mock _code2country to return our mock country object
		my $mock_lingua = Test::MockModule->new('CGI::Lingua');
		$mock_lingua->mock('_code2country', sub {
			my ($self, $code) = @_;
			return bless { code => lc $code }, 'Locale::Object::Country';
		});

		my $lingua = CGI::Lingua->new(supported => ['en']);
		$mock_lingua->mock('_code2country', sub { undef });

		ok(!defined $lingua->locale(), 'Undefined for invalid country code');
	};
	Test::MockModule->unmock_all();
};

subtest 'IPv6 Handling' => sub {
	my $ipv6_public = '2001:db8::1';	# Test documentation IP
	my $ipv6_private = 'fd00::1';	# ULA private IP
	my $ipv6_loopback = '::1';
	my $ipv6_v4mapped = '::ffff:192.0.2.1';

	# Mock IP::Country for IPv6
	$mock_ip_country->mock('inet_atocc', sub {
		my ($self, $ip) = @_;
		return $ip eq $ipv6_public ? 'DE' : undef;
	});

	subtest 'Public IPv6' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => $ipv6_public);

		my $lingua = CGI::Lingua->new(
			supported => ['en'],
			cache => $cache,
		);

		is($lingua->country, 'de', 'Country from IPv6 via IP::Country mock');
		ok($cache->get("CGI::Lingua:country:$ipv6_public"), 'IPv6 result cached');
	};

	subtest 'Private IPv6' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => $ipv6_private);

		my $lingua = CGI::Lingua->new(supported => ['en']);
		ok(!defined $lingua->country, 'Undefined for private IPv6');
	};

	subtest 'Loopback IPv6' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => $ipv6_loopback);

		my $lingua = CGI::Lingua->new(supported => ['en']);
		ok(!defined $lingua->country, 'Undefined for IPv6 loopback');
	};

	subtest 'v4-Mapped IPv6' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => $ipv6_v4mapped);

		my $lingua = CGI::Lingua->new(
			supported => ['en'],
			cache => $cache,
		);

		# Should treat as IPv4 192.0.2.1
		$mock_ip_country->mock('inet_atocc', sub { 'US' });

		is($lingua->country, 'us', 'Handle v4-mapped IPv6 as IPv4');
	};

	subtest 'Fallback to External API' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => $ipv6_public);

		# Disable IP::Country mock
		$mock_ip_country->unmock('inet_atocc');

		my $lingua = CGI::Lingua->new(
			supported => ['en'],
			cache => $cache,
		);

		is($lingua->country(), 'de', 'Country from external API for IPv6');
	};

	subtest 'Invalid IPv6' => sub {
		local %ENV = (%{$mock_env}, REMOTE_ADDR => 'garbage::v6');

		my $lingua = CGI::Lingua->new(supported => ['en']);
		delete $lingua->{logger};

		warning_like { $lingua->country() } qr/valid IP address/i,
			'Warns on invalid IPv6 format';
	};
};

subtest 'Sublanguage Handling' => sub {
	diag('FIXME: there are bugs I need to fix');
	# Mock environment setup
	my $mock_env = {
		REMOTE_ADDR => '123.45.67.89',
		HTTP_USER_AGENT => 'Mozilla/5.0'
	};

	# Mock country to avoid IP lookup
	my $mock_ip_country = Test::MockModule->new('IP::Country::Fast');
	$mock_ip_country->mock('inet_atocc', sub { 'US' });

	subtest 'Exact Sublanguage Match' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'en-gb, en;q=0.9');
		
		my $lingua = CGI::Lingua->new(
			supported => ['en-gb', 'en-us', 'fr'],
			cache => $cache,
		);

		is($lingua->language(), 'English', 'Base language correct');
		cmp_ok($lingua->sublanguage(), 'eq', 'United Kingdom', 'Exact sublanguage match');
		is $lingua->sublanguage_code_alpha2, 'gb', 'Correct sublanguage code';
		like $lingua->requested_language, qr/English.*United Kingdom/,
			'Shows full requested language';
		diag(Data::Dumper->new([$lingua->{'messages'}])->Dump()) if($ENV{'TEST_VERBOSE'});
	};

	subtest 'Base Language Fallback' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'en-us');
		
		my $lingua = CGI::Lingua->new(
			supported => ['en', 'fr'],
			cache => $cache,
		);

		is $lingua->language, 'English', 'Falls back to base language';
		ok(!defined $lingua->sublanguage(), 'No sublanguage defined');
		is $lingua->language_code_alpha2, 'en', 'Base language code';
		like $lingua->requested_language, qr/English.*United States/,
			'Shows requested sublanguage';
	};

	subtest 'Closest Sublanguage Match' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'en');
		
		my $lingua = CGI::Lingua->new(
			supported => ['en-gb', 'en-ca'],
			cache => $cache,
		);

		is $lingua->language, 'English', 'Base language maintained';
		like($lingua->sublanguage, qr/(United Kingdom|Canada)/, 'Selects first available sublanguage');
	};

	subtest 'Case Insensitivity' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'EN-GB');
		
		my $lingua = CGI::Lingua->new(
			supported => ['en-gb'],
			cache => $cache,
		);

		is $lingua->sublanguage_code_alpha2, 'gb', 
			'Handles uppercase language tags';
	};

	subtest 'Three-Part Language Tags' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'es-419');
		
		my $lingua = CGI::Lingua->new(
			supported => ['es', 'es-es'],
			cache => $cache,
		);

		is $lingua->language, 'Spanish', 'Handles regional codes';
		ok(!defined $lingua->sublanguage, 'No sublanguage for es-419');
	};
	
	
	subtest 'Country-Specific Default' => sub {
		local %ENV = (%{$mock_env}, 
			HTTP_ACCEPT_LANGUAGE => 'en-us',
			REMOTE_ADDR => '8.8.8.8'	# US IP
		);
		
		$mock_ip_country->mock('inet_atocc', sub { 'US' });
		
		my $opts = {
			supported => ['en', 'en-gb', 'en-us'],
			cache => $cache
		};

		if($ENV{'TEST_VERBOSE'}) {
			$opts->{'debug'} = 1;
			$opts->{'logger'} = sub { diag(@{$_[0]->{'message'}}) };
		}

		my $lingua = CGI::Lingua->new($opts);

		eval {
			is($lingua->sublanguage_code_alpha2(), 'us', 'Auto-selects country-specific sublanguage');
		};
		diag($@) if($@);
	};
	

	subtest 'Deprecated Codes' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'en-uk');
		
		my $opts = {
			supported => ['en-gb'],
			cache => $cache
		};

		if($ENV{'TEST_VERBOSE'}) {
			$opts->{'debug'} = 1;
			$opts->{'logger'} = sub { diag(@{$_[0]->{'message'}}) };
		}

		my $lingua = CGI::Lingua->new($opts);

		eval {
			is($lingua->sublanguage_code_alpha2(), 'gb', 'Converts deprecated UK code to GB');
		};
		diag($@) if($@);
	};

	subtest 'Quality Values' => sub {
		local %ENV = (%{$mock_env}, 
			HTTP_ACCEPT_LANGUAGE => 'en-gb;q=0.7, en-us;q=0.9'
		);
		
		my $opts = {
			supported => ['en-gb', 'en-us'],
			cache => $cache
		};

		if($ENV{'TEST_VERBOSE'}) {
			$opts->{'debug'} = 1;
			$opts->{'logger'} = sub {
				my $params = $_[0];
				diag($params->{'function'}, ': line ', $params->{'line'}, ': ', @{$params->{'message'}})
			}
		}

		my $lingua = CGI::Lingua->new($opts);
		eval {
			cmp_ok($lingua->sublanguage_code_alpha2(), 'eq', 'us', "Honours quality values in Accept-Language ('$ENV{HTTP_ACCEPT_LANGUAGE}' should be en-us not en-gb)");
		};
		diag($@) if($@);
	};

	subtest 'Invalid Sublanguage' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'en-xx');
		
		my $opts = {
			supported => ['en'],
			cache => $cache,
		};

		if($ENV{'TEST_VERBOSE'}) {
			$opts->{'debug'} = 1;
			$opts->{'logger'} = sub {
				my $params = $_[0];
				diag($params->{'function'}, ': line ', $params->{'line'}, ': ', @{$params->{'message'}})
			}
		}
		my $lingua = new_ok('CGI::Lingua' => [ $opts ]);

		cmp_ok($lingua->language(), 'eq', 'English', 'Valid base language');
		like($lingua->requested_language(), qr/Unknown.*xx/, 'Shows unknown sublanguage');
		ok(!defined($lingua->sublanguage()));
	};

	subtest 'Cached Sublanguage' => sub {
		local %ENV = (%{$mock_env}, HTTP_ACCEPT_LANGUAGE => 'fr-be');
		
		my $lingua = CGI::Lingua->new(
			supported => ['fr', 'fr-ca'],
			cache => $cache,
		);

		# First call
		is($lingua->language(), 'French', 'Initial call');
		
		# Second call with same params
		my $lingua2 = CGI::Lingua->new(
			supported => ['fr', 'fr-ca'],
			cache => $cache,
		);

		is($lingua2->language(), 'French', 'Cached result');
	};
	Test::MockModule->unmock_all();
};

subtest 'should load config file if provided' => sub {
	my ($fh, $config_file) = tempfile(TEMPLATE => 'test_configXXXX', SUFFIX => '.yml', TMPDIR => 1);
	print $fh "---\nsupported: fr\n";
	close $fh;

	my $info = CGI::Lingua->new(config_file => $config_file);
	is($info->{'supported'}, 'fr', 'Config file loaded correctly');
	unlink $config_file;
};

done_testing();
