#!/usr/bin/perl -I ../lib
use strict;
use warnings;
use Test::More tests => 10;
use File::Temp qw/tempfile/;

# Create temporary test document

my ($tmp_fh, $tmp_name) = tempfile('/tmp/phonechallenge.XXXXX', UNLINK => 0);

print $tmp_fh <<EOF;
<?xml version="1.0"?>
<users>
	<user id="1234">
		<token challenge="1" response="1234" used="0"/>
		<token challenge="2" response="3456" used="0"/>
	</user>
	<user id="5678">
		<token challenge="1" response="9876" used="0"/>
		<token challenge="2" response="3498" used="0"/>
	</user>
</users>
EOF

close $tmp_fh;

use_ok('Authen::PhoneChallenge');
require_ok('Authen::PhoneChallenge');

my $auth = new Authen::PhoneChallenge($tmp_name);

# Checks with invalid user
ok(!($auth->set_user(1398)), 'Set invalid user');
ok(!($auth->get_challenge()), 'Get challenge for invalid user');
ok(!($auth->check_response('4592')), 'Check response for invalid user');
ok(!($auth->check_response()), 'Check empty response');

# Checks with valid user
ok($auth->set_user(1234), 'Set valid user');
my $chall = $auth->get_challenge;
ok($chall, 'Get challenge for valid user');

my $response = {
	1	=> 1234,
	2	=> 3456,
};

ok($auth->check_response($response->{$chall}), 'Check valid response');
ok(!($auth->check_response(4)), 'Check invalid response');

unlink $tmp_name;
