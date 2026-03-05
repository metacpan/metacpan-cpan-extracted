#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 21;
use Test::MockObject;

BEGIN { use_ok('CGI::ACL') };

# Testing 'new' method
{
	my $acl = new_ok('CGI::ACL');

	my $acl_with_args = CGI::ACL->new(allowed_ips => { '127.0.0.1' => 1 });
	ok($acl_with_args, 'Object created with arguments');
	ok(exists $acl_with_args->{allowed_ips}->{'127.0.0.1'}, 'Arguments set correctly');
}

# Testing 'allow_ip'
{
	my $acl = CGI::ACL->new();
	ok($acl->allow_ip(ip => '192.168.1.1'), 'IP allowed');
	ok(exists $acl->{allowed_ips}->{'192.168.1.1'}, 'IP stored in allowed list');
}

# Testing 'deny_country'
{
	my $acl = CGI::ACL->new();
	ok($acl->deny_country(country => 'GB'), 'Country denied');
	ok(exists $acl->{deny_countries}->{'gb'}, 'Country stored in deny list');

	my @countries = ('GB', 'US');
	ok($acl->deny_country(country => \@countries), 'Multiple countries denied');
	foreach my $c (@countries) {
		ok(exists $acl->{deny_countries}->{lc($c)}, "Country $c stored in deny list");
	}
}

# Testing 'allow_country'
{
	my $acl = CGI::ACL->new();
	ok($acl->allow_country(country => 'US'), 'Country allowed');
	ok(exists $acl->{allow_countries}->{'us'}, 'Country stored in allow list');

	my @countries = ('GB', 'US');
	ok($acl->allow_country(country => \@countries), 'Multiple countries allowed');
	foreach my $c (@countries) {
		ok(exists $acl->{allow_countries}->{lc($c)}, "Country $c stored in allow list");
	}
}

# Testing 'all_denied'
{
	my $acl = CGI::ACL->new();

	# Test default behavior (no restrictions set)
	is($acl->all_denied(), 0, 'Default behavior: access allowed');

	# Test IP restriction
	$acl->allow_ip(ip => '192.168.1.1');
	local $ENV{'REMOTE_ADDR'} = '192.168.1.1';
	is($acl->all_denied(), 0, 'Access allowed for allowed IP');

	local $ENV{'REMOTE_ADDR'} = '192.168.1.2';
	is($acl->all_denied(), 1, 'Access denied for unlisted IP');

	# Test country restriction
	my $mock_lingua = Test::MockObject->new();
	$mock_lingua->mock('country', sub { 'US' });

	$acl = CGI::ACL->new()->deny_country('*')->allow_country(country => 'US');
	is($acl->all_denied(lingua => $mock_lingua), 0, 'Access allowed for allowed country');

	$mock_lingua->mock('country', sub { 'GB' });
	is($acl->all_denied(lingua => $mock_lingua), 1, 'Access denied for unlisted country');
}
