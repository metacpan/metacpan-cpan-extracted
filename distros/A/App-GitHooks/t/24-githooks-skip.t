#!perl

use strict;
use warnings;

use App::GitHooks;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

plan( tests => 11 );

local $App::GitHooks::HOOK_NAMES = [ @$App::GitHooks::HOOK_NAMES, 'test-hook' ];

my $exit_code = 'exit code';

sub App::GitHooks::Hook::TestHook::run { $exit_code }

sub run_the_test_hook
{
	my ( $expected_value, $comment ) = @_;
	is(
		App::GitHooks->run(
			name => 'test-hook',
			exit => 0,
		),
		$expected_value,
		$comment
	);
}

run_the_test_hook(
	$exit_code,
	'Hook was run.'
);

my $var_name;
local $SIG{__WARN__} = sub
{
	my ($warning) = @_;
	like(
		$warning,
		qr/Hook test-hook skipped because of $var_name/,
		'Correct warning'
	);
};

{
local $ENV{ $var_name = 'GITHOOKS_SKIP' } = 'test-hook';
	run_the_test_hook(
		$App::GitHooks::HOOK_EXIT_SUCCESS,
		'Hook was skipped when specified alone.'
	);

	$ENV{'GITHOOKS_SKIP'} = 'test-hook,yyy';
	run_the_test_hook(
		$App::GitHooks::HOOK_EXIT_SUCCESS,
		'Hook was skipped when specified at the beginning.'
	);

	$ENV{'GITHOOKS_SKIP'} = 'xxx,test-hook,yyy';
	run_the_test_hook(
		$App::GitHooks::HOOK_EXIT_SUCCESS,
		'Hook was skipped when specified in the middle.'
	);

	$ENV{'GITHOOKS_SKIP'} = 'xxx,test-hook';
	run_the_test_hook(
		$App::GitHooks::HOOK_EXIT_SUCCESS,
		'Hook was skipped when specified as last.'
	);
}

{
	local $ENV{ $var_name = 'GITHOOKS_DISABLE' } = 1;
	run_the_test_hook(
		$App::GitHooks::HOOK_EXIT_SUCCESS,
		'Hooks were disabled.'
	);
}
