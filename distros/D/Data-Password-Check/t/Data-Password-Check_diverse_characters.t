#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 21;

BEGIN {
	use_ok( q{Data::Password::Check} );
}

my (@tests, $pwcheck);

@tests = (
	# this should succeed, we aren't demanding much diversity
	{
		password		=> '111111122233333',
		diversity		=> 1,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should succeed, we aren't demanding much diversity
	{
		password		=> 'aaaaaaaa',
		diversity		=> 1,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should fail, not diverse enough
	{
		password		=> '112143432',
		diversity		=> 2,
		expect_error	=> 1,
		error_msg		=> q{Your password must contain a good mix of character types},
	},
	# this should fail, not diverse enough
	{
		password		=> 'aaaaaaaa',
		diversity		=> 2,
		expect_error	=> 1,
		error_msg		=> q{Your password must contain a good mix of character types},
	},
	# this should succeed, a bit of diversity required and supplied
	{
		password		=> '_aaaaaaaa',
		diversity		=> 2,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should succeed, a bit of diversity required and supplied
	{
		password		=> '1aaaaaaaa',
		diversity		=> 2,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should succeed, a bit of diversity required and supplied
	{
		password		=> 'AaaaaaaaaA',
		diversity		=> 2,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should fail, not diverse enough
	{
		password		=> 'AaaaaaaaaA',
		diversity		=> 3,
		expect_error	=> 1,
		error_msg		=> q{Your password must contain a good mix of character types},
	},
	# this should succeed, a bit of diversity required and supplied
	{
		password		=> '_aaaaaaaaA',
		diversity		=> 3,
		expect_error	=> 0,
		error_msg		=> undef,
	},
	# this should succeed, a bit of diversity required and supplied
	{
		password		=> '1aaaaaaaaA',
		diversity		=> 3,
		expect_error	=> 0,
		error_msg		=> undef,
	},
);

foreach my $test (@tests) {
	# make the check
	$pwcheck = Data::Password::Check->check(
		{
			tests 				=> [ 'diverse_characters' ],	# make sure we aren't running any other checks
			password			=> $test->{password},
			diversity_required	=> $test->{diversity},
		}
	);
	# were we expecting an error?
	if ($test->{expect_error}) {
		is(
			$pwcheck->has_errors(),
			1,
			qq{received expected error for $test->{password}}
		);
	}
	else {
		isnt(
			$pwcheck->has_errors(),
			1,
			qq{no error for $test->{password}}
		);
	}

	# if we don't expect an error, but get one ...
	if ($pwcheck->has_errors && not $test->{'expect_error'}) {
		diag qq{recieved an unexpected error for $test->{password}};
		die Dumper( $pwcheck->error_list );
	}

	# skip the error message test if we didn't have an error
	SKIP: {
		# skip the test if we don't have errors
		skip "No errors returned from password check - no error message to verify", 1 unless $pwcheck->has_errors();
		# otherwise make sure we have an appropriate error message
		like(
			$pwcheck->error_list()->[0],
			qr/$test->{'error_msg'}/,
			qq{error message matches expected string}
		);
	}
}
