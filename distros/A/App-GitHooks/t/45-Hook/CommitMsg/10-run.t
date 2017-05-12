#!/usr/bin/env perl

use strict;
use warnings;

use App::GitHooks::Constants qw( :HOOK_EXIT_CODES );
use App::GitHooks::Test;


# Since git ignores the return value of the hook, we can't test using the exit
# code here. Instead, we use the App::GitHooks::Plugin::Test::PrintSTDERR,
# which allows us to verify that the hook was properly triggered and that
# plugins for that hook are loaded correctly.

# List of tests to perform.
my $tests =
[
	{
		name        => 'Trigger plugins for commit-msg.',
		config      => "[Test::PrintSTDERR]\n"
			. "commit_msg = Triggered commit-msg.\n",
		expected    => qr/Triggered commit-msg./,
		exit_status => $HOOK_EXIT_SUCCESS,
	},
];

# Run tests.
App::GitHooks::Test::test_hook(
	cleanup_test_repository => 1,
	hook_name               => 'commit-msg',
	plugins                 => [ 'App::GitHooks::Plugin::Test::PrintSTDERR' ],
	tests                   => $tests,
);
