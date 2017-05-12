#!perl

use strict;
use warnings;

use App::GitHooks;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 8 );

can_ok(
	'App::GitHooks',
	'force_non_interactive',
);

ok(
	defined(
		my $app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg',
		),
	),
	'Create a new App::GitHooks object.',
);

is(
	$app->force_non_interactive(),
	0,
	'Force is not set by default.',
);

throws_ok(
	sub
	{
		$app->force_non_interactive( 'test' );
	},
	qr/Invalid argument/,
	'Require a valid argument.',
);

lives_ok(
	sub
	{
		$app->force_non_interactive( 1 );
	},
	'Force non-interactive.',
);

is(
	$app->force_non_interactive(),
	1,
	'Force is now set.',
);

lives_ok(
	sub
	{
		$app->force_non_interactive( 0 );
	},
	'Go back to not forcing non-interactive.',
);

is(
	$app->force_non_interactive(),
	0,
	'Force is now not set.',
);



