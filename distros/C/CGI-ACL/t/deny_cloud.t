use strict;
use warnings;

use Test::Most;
use Test::MockModule;

BEGIN { use_ok('CGI::ACL') }

# ------------------------------------------------------------
# Mock verified_rdns() so tests do not depend on real DNS
# ------------------------------------------------------------

my $mock = Test::MockModule->new('CGI::ACL');

$mock->mock('verified_rdns', sub {
	my $ip = $_[0];

	return 'ec2-1-2-3-4.compute-1.amazonaws.com' if $ip eq '1.2.3.4';   # AWS

	return '203-0-113-10.bc.googleusercontent.com' if $ip eq '203.0.113.10';  # GCP

	return 'customer-5-6-7-8.example.com' if $ip eq '5.6.7.8';   # Residential / non-cloud

	return undef;              # No PTR or unverified
});

# ------------------------------------------------------------
# Create ACL with cloud blocking enabled
# ------------------------------------------------------------

my $acl = CGI::ACL->new()->deny_cloud()->allow_ip('1.2.3.4')->allow_ip('203.0.113.10')->allow_ip('5.6.7.8')->allow_ip('198.51.100.99');

# Helper to call all_denied() with a fake REMOTE_ADDR
sub denied_for {
    my ($ip) = @_;
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

done_testing();
