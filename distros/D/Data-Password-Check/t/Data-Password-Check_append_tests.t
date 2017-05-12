# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Password-Check.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Data::Password::Check') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# This test file uses the default setup, and just pokes to make sure that we get failures
# when we expect them

my ($pwcheck);

# we want to create a check object, append a non-default test, run
# the check with a password that fails the test and look for an appropriate error
# message for the failed check

# list of passwords and expected errors
# EVERY TIME YOU ADD A NEW TEST you need to increase "tests => " by 2
my @tests = (
	# qwerty should be rejected as a silly word
	{
		'password'		=> 'qwerty!',
		'append_tests'	=> [ 'alphanumeric_only' ],
		'error_msg'		=> qr{^Your password may only contain alphanumeric characters},
	},
);

# run each test in turn, lokk for errors, and make sure they match what we expect
foreach my $test (@tests) {
	# check the password
	$pwcheck = Data::Password::Check->check(
		{
			'password'		=> $test->{'password'},
			'append_tests'	=> $test->{'append_tests'},
		}
	);
	# make sure we have an error
	ok($pwcheck->has_errors());
	# make sure we have an appropriate error message somewhere in the error list
	ok( grep { /$test->{'error_msg'}/ } @{$pwcheck->error_list()} );
}
