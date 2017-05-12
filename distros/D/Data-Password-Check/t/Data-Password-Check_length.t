# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Password-Check.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Data::Password::Check') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# This file is used to test the length test
my (@tests, $pwcheck, $too_short_errmsg);

# testing that we get errors back when we use stupid values
@tests = (
	# we should get an error because min_length is stupid
	{
		'password'		=> 'qwerty',
		'min_length'	=> '-1',
	},
	# we should get an error because min_length is stupid
	{
		'password'		=> 'qwerty',
		'min_length'	=> 'twelve',
	},
	# we should get an error because min_length is stupid
	{
		'password'		=> 'qwerty',
		'min_length'	=> '1.2',
	},
	# we should get an error because min_length is stupid
	{
		'password'		=> 'qwerty',
		'min_length'	=> undef,
	},
);

# make a call to check(), run it inside an eval()
foreach my $test (@tests) {
	local $SIG{__WARN__} = sub { 1 };

	$pwcheck = Data::Password::Check->check({
		'password'		=> $test->{'password'},
		'min_length'	=> $test->{'min_length'},
		'tests'			=> [ 'length' ],			# don't want to run any other tests
	});

	# we're ok if we skipped the test (because of the errors)
	ok($pwcheck->_skipped_test('length'));
}


# we're going to repeat this a lot I expect
$too_short_errmsg = qr{^The password must be at least \d+ characters?$};

# list of passwords and expected errors
@tests = (
	# this should pass, length(qwerty) > 1
	{
		'password'		=> 'qwerty',
		'min_length'	=> 1,
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},
	# this should pass, length(q) >= 1
	{
		'password'		=> 'q',
		'min_length'	=> 1,
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},

	# this should fail, too short
	{
		'password'		=> '',
		'min_length'	=> 1,
		'expect_error'	=> 1,
		'error_msg'		=> $too_short_errmsg,
	},
	# this should fail, undefined
	{
		'password'		=> undef,
		'min_length'	=> 1,
		'expect_error'	=> 1,
		'error_msg'		=> $too_short_errmsg,
	},
);

# run each test in turn, look for errors, and make sure they match what we expect
foreach my $test (@tests) {
	# check the password
	$pwcheck = Data::Password::Check->check({
		'password'		=> $test->{'password'},
		'min_length'	=> $test->{'min_length'},
		'tests'			=> [ 'length' ],			# don't want to run any other tests
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
