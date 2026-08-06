#!perl -wT

use strict;
use warnings;
use Test::Most tests => 38;
use Test::Carp;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::ACL');
	use_ok('CGI::Lingua');
}

COUNTRY: {
	my $acl = new_ok('CGI::ACL');

	$acl->deny_country('gb');
	$ENV{'REMOTE_ADDR'} = '212.159.106.41';	# F9

	my $lingua = new_ok('CGI::Lingua', [ supported => ['en'] ]);

	# Resolve the country once while REMOTE_ADDR is set; suppress WHOIS
	# warnings that appear when RIPE is rate-limiting.  Both tests that require
	# the GB country ('gb') are gated on $gb_country being defined so they are
	# gracefully skipped rather than failing during RIPE rate-limit windows.
	my $gb_country = do { local $SIG{__WARN__} = sub {}; $lingua->country() };

	SKIP: {
		skip 'RIPE WHOIS unavailable for GB IP (212.159.106.41)', 1
			unless defined $gb_country;
		is($gb_country, 'gb');
	}
	ok($acl->all_denied(lingua => $lingua));

	my @country_list = (
		'BY', 'MD', 'RU', 'CN', 'BR', 'UY', 'TR', 'MA', 'VE', 'SA', 'CY',
		'CO', 'MX', 'IN', 'RS', 'PK', 'UA', 'GB',
	);
	$acl = new_ok('CGI::ACL')
		->deny_country({ country => \@country_list });

	ok($acl->all_denied({ lingua => $lingua }));

	$acl->allow_ip({ ip => '212.159.106.0/24' });	# F9

	ok(!$acl->all_denied($lingua));

	$ENV{'REMOTE_ADDR'} = '87.226.159.0';	# RT

	ok($acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$ENV{'REMOTE_ADDR'} = '130.14.25.184';	# NCBI

	ok(!$acl->all_denied(new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$acl = new_ok('CGI::ACL');

	# Test countries in an array
	@country_list = ('GB', 'US');
	$acl->deny_country('*')->allow_country(country => \@country_list);

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';	# F9

	# Wildcard-deny + allow GB: $lingua must resolve to 'gb' for the ACL to
	# allow it.  Skip when RIPE is rate-limited (same $gb_country guard as
	# the is() test above — no additional WHOIS call needed).
	SKIP: {
		skip 'RIPE WHOIS unavailable for GB IP (212.159.106.41)', 1
			unless defined $gb_country;
		ok(!$acl->all_denied(lingua => $lingua));
	}

	$ENV{'REMOTE_ADDR'} = '87.226.159.0';	# RT

	ok($acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$ENV{'REMOTE_ADDR'} = '127.0.0.1';
	ok($acl->all_denied(new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	# Test country in a scalar
	$acl = new_ok('CGI::ACL');
	$acl->deny_country('*')->allow_country('US');

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';	# F9

	ok($acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$ENV{'REMOTE_ADDR'} = '130.14.25.184';	# NCBI

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	does_carp(sub { $acl->deny_country() });
	does_carp(sub { $acl->deny_country(\'not a ref to a hash') });
	does_carp(sub { $acl->allow_country({}) });
	does_carp(sub { $acl->allow_country(\'not a ref to a hash') });
	does_carp(sub { $acl->all_denied() });

	# Verify bad-ref calls still return $self so method chaining is not broken
	my ($dc_ret, $ac_ret);
	does_carp(sub { $dc_ret = $acl->deny_country(\'bad ref') });
	isa_ok($dc_ret, 'CGI::ACL', 'deny_country returns $self on bad ref');
	does_carp(sub { $ac_ret = $acl->allow_country(\'bad ref') });
	isa_ok($ac_ret, 'CGI::ACL', 'allow_country returns $self on bad ref');
}
