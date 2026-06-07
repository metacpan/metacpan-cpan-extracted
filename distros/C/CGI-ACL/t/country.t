#!perl -wT

use strict;
use warnings;
use Test::Most tests => 39;
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

	is($lingua->country(), 'gb');
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

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

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
