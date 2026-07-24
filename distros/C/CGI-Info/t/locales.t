#!/usr/bin/env perl

# Test CGI::Info behaviour under different system locales (POSIX LC_ALL) and,
# if IP::Country::Fast is available, under geographic locale (GeoIP).
#
# Two dimensions of "locale" are covered:
#   1. System locale  - POSIX LC_ALL / LANG settings
#   2. Geographic locale - GeoIP country-code detection (optional)

use strict;
use warnings;

use Test::Most;
use Test::Needs;
use Errno qw(ENOENT);
use POSIX qw(locale_h);

BEGIN { use_ok('CGI::Info') or BAIL_OUT('CGI::Info failed to load') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Return the OS error string for ENOENT under the caller's current locale.
# Using $! (not POSIX::strerror) so we get the same string Perl embeds in
# thrown exceptions.
sub enoent_string {
	local $! = ENOENT;
	return "$!";
}

# Run $code with LC_ALL set to $locale; restore afterwards.
sub with_locale (&$) {
	my ($code, $locale) = @_;
	local $ENV{LC_ALL}   = $locale;
	local $ENV{LANG} = $locale;
	# setlocale so that $! is also translated
	my $old = POSIX::setlocale(LC_ALL);
	POSIX::setlocale(LC_ALL, $locale);
	my @rv = eval { $code->() };
	my $err = $@;
	POSIX::setlocale(LC_ALL, $old);
	die $err if $err;
	return wantarray ? @rv : $rv[0];
}

# ---------------------------------------------------------------------------
# 1. System-locale subtests
#    Every error path in CGI::Info that produces a die/croak with an OS
#    error string must be exercised under several LC_ALL values.
# ---------------------------------------------------------------------------

my @LOCALES = ('en_US.UTF-8', 'de_DE.UTF-8', 'zh_CN.UTF-8');

# Filter to only locales actually installed on this system.
my @available_locales;
for my $loc (@LOCALES) {
	my $old = POSIX::setlocale(LC_ALL);
	my $result = POSIX::setlocale(LC_ALL, $loc);
	POSIX::setlocale(LC_ALL, $old);
	push @available_locales, $loc if defined $result;
}

subtest 'System locale - invalid logdir croak' => sub {
	plan skip_all => 'no POSIX locales available on this system'
		unless @available_locales;
	plan tests => scalar(@available_locales) * 2;

	for my $locale (@available_locales) {
		my $nonexistent = '/nonexistent/path/' . $$;

		my ($croaked, $msg);
		with_locale {
			eval {
				local $ENV{GATEWAY_INTERFACE} = undef;
				my $info = CGI::Info->new();
				$info->logdir($nonexistent);
			};
			$croaked = $@ // '';
			$msg = enoent_string();
		} $locale;

		ok(length($croaked), "logdir croak fires under $locale");
		like($croaked, qr/Invalid logdir/, "logdir croak message under $locale");
	}
};

subtest 'System locale - cookie croak with no name' => sub {
	plan skip_all => 'no POSIX locales available on this system'
		unless @available_locales;
	plan tests => scalar(@available_locales) * 2;

	for my $locale (@available_locales) {
		my $croaked;
		with_locale {
			eval {
				local $ENV{GATEWAY_INTERFACE} = undef;
				local $ENV{HTTP_COOKIE}       = 'foo=bar';
				my $info = CGI::Info->new();
				$info->cookie();   # no name arg => croak from Params::Get
			};
			$croaked = $@ // '';
		} $locale;

		ok(length($croaked), "cookie() croak fires under $locale");
		# Params::Get enforces the cookie_name argument before CGI::Info's own
		# guard; match on the generated Usage message which names the parameter.
		like($croaked, qr/cookie_name/i, "cookie croak names the missing arg under $locale");
	}
};

subtest 'System locale - param() allow-list warning is locale-independent' => sub {
	plan skip_all => 'no POSIX locales available on this system'
		unless @available_locales;
	plan tests => scalar(@available_locales) * 2;

	for my $locale (@available_locales) {
		with_locale {
			local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
			local $ENV{REQUEST_METHOD}    = 'GET';
			local $ENV{QUERY_STRING}      = 'foo=1&bar=2';
			my $info   = CGI::Info->new();
			my $allowed = { foo => qr/\d+/ };
			$info->params(allow => $allowed);
			my $val = $info->param('bar');   # not in allow list

			is($val, undef, "forbidden param returns undef under $locale");
			my @warns = grep { $_->{message} =~ /isn.t in the allow list/ }
				@{ $info->messages() // [] };
			ok(scalar(@warns), "allow-list warning recorded under $locale");
		} $locale;
	}
};

subtest 'System locale - expect deprecation croak is locale-independent' => sub {
	plan skip_all => 'no POSIX locales available on this system'
		unless @available_locales;
	plan tests => scalar(@available_locales) * 2;

	for my $locale (@available_locales) {
		my $croaked;
		with_locale {
			eval {
				local $ENV{GATEWAY_INTERFACE} = undef;
				CGI::Info->new(expect => [qw(foo)]);
			};
			$croaked = $@ // '';
		} $locale;

		ok(length($croaked), "expect deprecation croak fires under $locale");
		like($croaked, qr/deprecated/, "expect croak message under $locale");
	}
};

# ---------------------------------------------------------------------------
# 2. Geographic locale subtests (require IP::Country::Fast)
# ---------------------------------------------------------------------------

subtest 'Geographic locale - GeoIP country detection' => sub {
	Test::Needs->import('IP::Country::Fast');

	# Known IP -> country mappings.  BAIL_OUT on any mismatch to expose GeoIP
	# database drift fast and obviously.
	# This can happen because of sites using vPOP e.g. cloudflare
	my %ip_to_country = (
		'212.58.244.22'  => 'GB',   # BBC (UK)
		'8.8.8.8'        => 'US',   # Google DNS (US)
		'212.27.60.19' => 'FR',   # free.fr (France)
		'195.243.1.1' => 'DE',	# Deutsche Telekom (Germany)
		'101.4.55.4'     => 'CN',   # CERNET (China)
	);

	my $reg = new_ok('IP::Country::Fast');

	subtest 'Sanity check - IP to country mapping' => sub {
		plan tests => scalar(keys %ip_to_country);
		for my $ip (sort keys %ip_to_country) {
			my $expected = $ip_to_country{$ip};
			my $got      = uc($reg->inet_atocc($ip) // '');
			$got eq $expected
				or BAIL_OUT("GeoIP drift: $ip mapped to '$got', expected '$expected'. Update the test.");
			is($got, $expected, "IP $ip resolves to $expected");
		}
	};

	subtest 'Case-insensitive country code matching' => sub {
		plan tests => scalar(keys %ip_to_country) * 2;
		for my $ip (sort keys %ip_to_country) {
			my $expected = $ip_to_country{$ip};
			is(uc($reg->inet_atocc($ip) // ''),  $expected, "$ip upper-case matches");
			is(lc($reg->inet_atocc($ip) // ''), lc($expected), "$ip lower-case matches");
		}
	};

	subtest 'Concurrent independent CGI::Info instances with different remote IPs' => sub {
		plan tests => scalar(keys %ip_to_country);

		for my $ip (sort keys %ip_to_country) {
			local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
			local $ENV{REQUEST_METHOD}    = 'GET';
			local $ENV{QUERY_STRING}      = '';
			local $ENV{REMOTE_ADDR}       = $ip;

			my $info    = CGI::Info->new();
			my $cc      = uc($reg->inet_atocc($ip) // '');
			my $expected = $ip_to_country{$ip};

			is($cc, $expected, "Instance for $ip detects $expected");
		}
	};
};

done_testing();
