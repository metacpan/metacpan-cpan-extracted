#!/usr/bin/env perl

use strict;
use warnings;

# Internal dependencies.
use App::GitHooks::Constants qw( :HOOK_EXIT_CODES );
use App::GitHooks::Hook;
use App::GitHooks::Test;
use App::GitHooks;

# External dependencies.
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 6 );

can_ok(
	'App::GitHooks::Hook',
	'run',
);

# Force a clean githooks config to ensure repeatable test conditions.
App::GitHooks::Test::ok_reset_githooksrc();

ok(
	push( @{ $App::GitHooks::HOOK_NAMES }, 'test-hook-name' ),
	'Add testing hook name.',
);

ok(
	defined(
		my $app = App::GitHooks->new(
			arguments => undef,
			name      => 'test-hook-name',
		)
	),
	'Instantiate a new App::GitHooks object.',
);

my $return;
lives_ok(
	sub
	{
		$return = App::GitHooks::Hook->run(
			app => $app,
		);
	},
	'Call run().',
);

is(
	$return,
	$HOOK_EXIT_SUCCESS,
	'The hook handler executed successfully.',
);
