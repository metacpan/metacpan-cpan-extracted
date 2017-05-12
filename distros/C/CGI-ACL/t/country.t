#!perl -wT

use strict;
use warnings;
use Test::Most tests => 16;
use Test::Carp;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::ACL');
	use_ok('CGI::Lingua');
}

COUNTRY: {
	my $acl = new_ok('CGI::ACL');

	$acl->deny_country('gb');
	$ENV{'REMOTE_ADDR'} = '212.159.106.41';

	my $lingua = new_ok('CGI::Lingua', [ supported => ['en'] ]);

	is($lingua->country, 'gb');
	ok($acl->all_denied(lingua => $lingua));

	my @country_list = (
		'BY', 'MD', 'RU', 'CN', 'BR', 'UY', 'TR', 'MA', 'VE', 'SA', 'CY',
		'CO', 'MX', 'IN', 'RS', 'PK', 'UA', 'GB',
	);
	$acl = new_ok('CGI::ACL')
		->deny_country(country => \@country_list);

	ok($acl->all_denied(lingua => $lingua));

	$acl->allow_ip({ ip => '212.159.106.0/24' });

	ok(!$acl->all_denied(lingua => $lingua));

	$ENV{'REMOTE_ADDR'} = '87.226.159.0';	# RT

	ok($acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	$ENV{'REMOTE_ADDR'} = '130.14.25.184';	# NCBI

	ok(!$acl->all_denied(lingua => new_ok('CGI::Lingua', [ supported => [ 'en' ] ])));

	does_carp(sub { $acl->deny_country() });

	does_carp(sub { $acl->all_denied() });
}
