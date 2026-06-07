use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

BEGIN { use_ok('CGI::ACL') }

# ------------------------------------------------------------
# Mock _verified_rdns so tests do not depend on real DNS
# ------------------------------------------------------------

my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
	my $ip = $_[0];

	return 'ec2-1-2-3-4.compute-1.amazonaws.com' if $ip eq '1.2.3.4';          # AWS IPv4
	return '203-0-113-10.bc.googleusercontent.com' if $ip eq '203.0.113.10';   # GCP IPv4
	return 'customer-5-6-7-8.example.com' if $ip eq '5.6.7.8';                 # Residential IPv4
	return 'ec2-v6.compute-1.amazonaws.com' if $ip eq '2001:db8::1';            # AWS IPv6
	return 'customer-v6.example.com' if $ip eq '2001:db8::2';                   # Residential IPv6
	return undef;	# No PTR or unverified
};

# ------------------------------------------------------------
# Create ACL with cloud blocking enabled
# ------------------------------------------------------------

my $acl = CGI::ACL->new()->deny_cloud()->allow_ip('1.2.3.4')->allow_ip('203.0.113.10')->allow_ip('5.6.7.8')->allow_ip('198.51.100.99');

# Helper to call all_denied() with a fake REMOTE_ADDR
sub denied_for {
	my $ip = $_[0];
	local $ENV{REMOTE_ADDR} = $ip;
	return $acl->all_denied();
}

# ------------------------------------------------------------
# Tests
# ------------------------------------------------------------

subtest 'AWS EC2 should be denied' => sub {
	ok denied_for('1.2.3.4'), 'AWS IP denied';
};

subtest 'Google Cloud should be denied' => sub {
	ok denied_for('203.0.113.10'), 'GCP IP denied';
};

subtest 'Residential IP should be allowed' => sub {
	ok !denied_for('5.6.7.8'), 'Non-cloud IP allowed';
};

subtest 'IP with no verified PTR should be allowed' => sub {
	ok !denied_for('198.51.100.99'), 'Unknown PTR allowed';
};

subtest 'deny_cloud alone (no allow_ip) blocks cloud IPs' => sub {
	my $cloud_only = CGI::ACL->new()->deny_cloud();
	local $ENV{REMOTE_ADDR} = '1.2.3.4';
	ok $cloud_only->all_denied(), 'AWS IP denied when only deny_cloud is set';

	local $ENV{REMOTE_ADDR} = '5.6.7.8';
	ok !$cloud_only->all_denied(), 'Residential IP allowed when only deny_cloud is set';
};

subtest 'IPv6 cloud IPs are denied, non-cloud IPv6 allowed' => sub {
	my $cloud_only = CGI::ACL->new()->deny_cloud();

	local $ENV{REMOTE_ADDR} = '2001:db8::1';
	ok $cloud_only->all_denied(), 'AWS IPv6 denied by deny_cloud';

	local $ENV{REMOTE_ADDR} = '2001:db8::2';
	ok !$cloud_only->all_denied(), 'Residential IPv6 allowed';
};

done_testing();
