# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Password-Check.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('Data::Password::Check') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# This file is used to test the length test
my (@tests, $pwcheck, $silly_word_errmsg);

# we're going to repeat this a lot I expect
$silly_word_errmsg = qr{^You may not use '.+?' as your password$};

# list of passwords and expected errors
@tests = (
	# OVERWRITE TESTS #

	# this should pass, qwerty not in (overridden) silly list
	{
		'password'		=> 'qwerty',
		'silly_words'	=> [ 'who cares', 'what', 'we', 'have', 'here' ],
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},
	# this should pass, we're not looking for substrings
	{
		'password'		=> 'qwerty',
		'silly_words'	=> [ 'qwertyuiop' ],
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},
	# this should pass, although password is in the default list, we have overwritten it
	{
		'password'		=> 'password',
		'silly_words'	=> [ 'qwerty' ],
		'expect_error'	=> 0,
		'error_msg'		=> undef,
	},

	# this should fail, should be obvious why
	{
		'password'		=> 'qwerty',
		'silly_words'	=> [ 'qwerty' ],
		'expect_error'	=> 1,
		'error_msg'		=> $silly_word_errmsg,
	},
	# this should fail, same as before but look for case insensitivity
	{
		'password'		=> 'QWerTy',
		'silly_words'	=> [ 'qwerty' ],
		'expect_error'	=> 1,
		'error_msg'		=> $silly_word_errmsg,
	},
	# this should also fail, we've just got more words in the list
	{
		'password'		=> 'QWerTy',
		'silly_words'	=> [ qw{password qwerty uiop asdf ghjkl pass} ],
		'expect_error'	=> 1,
		'error_msg'		=> $silly_word_errmsg,
	},


	# APPEND TESTS #
	
	# this should fail, password should be in the default list
	{
		'password'		=> 'password',
		'silly_words'	=> [ qw{foo bar baz} ],
		'append'		=> 1,
		'expect_error'	=> 1,
		'error_msg'		=> $silly_word_errmsg,
	},
	# this should fail, foo should be in the list because we appended it
	{
		'password'		=> 'foo',
		'silly_words'	=> [ qw{foo bar baz} ],
		'append'		=> 1,
		'expect_error'	=> 1,
		'error_msg'		=> $silly_word_errmsg,
	},
);

# run each test in turn, look for errors, and make sure they match what we expect
foreach my $test (@tests) {
	# we can either overwrite or append our list
	my $list_action = 'silly_words'; # default to overwrite
	# if we have 'append', and it's perl-true, change the action so that we append
	if (exists $test->{'append'} and $test->{'append'}) {
		$list_action = 'silly_words_append';
	}

	# check the password
	$pwcheck = Data::Password::Check->check({
		'password'		=> $test->{'password'},
		$list_action	=> $test->{'silly_words'},
		'tests'			=> [ 'silly' ],			# don't want to run any other tests
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
