#!perl -wT

use strict;
use warnings;
use Test::Most tests => 10;
use Test::NoWarnings;
use Test::Carp;

BEGIN {
	use_ok('CGI::ACL');
}

IP: {
	my $acl = new_ok('CGI::ACL');

	$acl->allow_ip('212.58.246.78');

	$ENV{'REMOTE_ADDR'} = '212.58.246.78';
	ok(!$acl->all_denied());

	$ENV{'REMOTE_ADDR'} = '8.35.80.39';
	ok($acl->all_denied());

	$acl = new_ok('CGI::ACL');

	$acl->allow_ip(ip => '8.0.0.0/8');
	ok(!$acl->all_denied());

	$ENV{'REMOTE_ADDR'} = '212.58.246.78';
	ok($acl->all_denied());

	does_carp(sub { $acl->allow_ip() });
	does_carp(sub { $acl->allow_ip(\'not a ref to a hash') });
}
