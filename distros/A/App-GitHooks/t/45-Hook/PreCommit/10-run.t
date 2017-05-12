#!/usr/bin/env perl

use strict;
use warnings;

use App::GitHooks::Constants qw( :HOOK_EXIT_CODES );
use App::GitHooks::Test;


# List of tests to perform.
my $tests =
[
	{
		name        => 'Global = FAIL and File = FAIL.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_FAILED\n"
			. "pre_commit_file = PLUGIN_RETURN_FAILED\n",
		expected    => qr/x Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_FAILURE,
	},
	{
		name        => 'Global = PASS and File = PASS.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_PASSED\n"
			. "pre_commit_file = PLUGIN_RETURN_PASSED\n",
		expected    => qr/o Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_SUCCESS,
	},
	{
		name        => 'Global = SKIP and File = SKIP.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_SKIPPED\n"
			. "pre_commit_file = PLUGIN_RETURN_SKIPPED\n",
		expected    => qr/- Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_SUCCESS,
	},
	{
		name        => 'Global = PASS and File = FAIL.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_PASSED\n"
			. "pre_commit_file = PLUGIN_RETURN_FAILED\n",
		expected    => qr/x Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_FAILURE,
	},
	{
		name        => 'Global = FAIL and File = PASS.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_FAILED\n"
			. "pre_commit_file = PLUGIN_RETURN_PASSED\n",
		expected    => qr/o Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_FAILURE,
	},
	{
		name        => 'Global = PASS and File = WARN.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_PASSED\n"
			. "pre_commit_file = PLUGIN_RETURN_WARNED\n",
		expected    => qr/! Test plugin - custom return codes/,
		exit_status => $HOOK_EXIT_SUCCESS,
	},
	{
		name        => 'Global = WARN and File = PASS.',
		config      => "[Test::CustomReply]\n"
			. "pre_commit = PLUGIN_RETURN_WARNED\n"
			. "pre_commit_file = PLUGIN_RETURN_PASSED\n",
		expected    => qr/\Qo Test plugin - custom return codes\E.*\QSome warnings were found, please review.\E/s,
		exit_status => $HOOK_EXIT_SUCCESS,
	},
];

# Run tests.
App::GitHooks::Test::test_hook(
	cleanup_test_repository => 1,
	hook_name               => 'pre-commit',
	plugins                 => [ 'App::GitHooks::Plugin::Test::CustomReply' ],
	tests                   => $tests,
);
