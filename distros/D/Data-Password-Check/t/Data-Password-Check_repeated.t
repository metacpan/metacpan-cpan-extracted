# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Password-Check.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Data::Password::Check') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# This file is used to test the length test
my (@tests, $pwcheck, $silly_word_errmsg);

# we're going to repeat this a lot I expect
$repeated_errmsg = qr{^You cannot use a single repeated character as a password$};

# list of passwords and expected errors
@tests = (
	# OVERWRITE TESTS #

	# this should pass, qwerty not repeated
	{
		'password'		=> 'qwerty',
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},
	# this should pass, not repeated a single character
	{
		'password'		=> 'abababab',
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},

	# this should fail, repeated
	{
		'password'		=> 'aaaaaaaa',
		'expect_error'	=> 1,
		'error_msg'		=> $repeated_errmsg,
	},
	# this should fail, repeated
	{
		'password'		=> '!!!!!!!!!',
		'expect_error'	=> 1,
		'error_msg'		=> $repeated_errmsg,
	},
);

# run each test in turn, look for errors, and make sure they match what we expect
foreach my $test (@tests) {
	# check the password
	$pwcheck = Data::Password::Check->check({
		'password'		=> $test->{'password'},
		'tests'			=> [ 'repeated' ],			# don't want to run any other tests
	});
	# were we expecting an error?
	if ($test->{'expect_error'}) {
		# did we get an error?
		ok($pwcheck->has_errors());
	}
	else {
		ok($pwcheck->has_errors() != 1);
	}

	# if we don't expect an error, but get one ...
	if ($pwcheck->has_errors && not $test->{'expect_error'}) { use Data::Dumper; die Dumper $pwcheck->error_list }

	# skip the error message test if we didn't have an error
	SKIP: {
		# skip the test if we don't have errors
		skip "No errors returned from password check - no error message to verify", 1 unless $pwcheck->has_errors();
		# make sure we have an appropriate error message
		ok($pwcheck->error_list()->[0] =~ /$test->{'error_msg'}/);
	}
}
