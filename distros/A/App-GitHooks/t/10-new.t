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
plan( tests => 7 );

can_ok(
	'App::GitHooks',
	'new',
);

throws_ok(
	sub
	{
		App::GitHooks->new(
			arguments => 'Test',
			name      => 'commit-msg',
		);
	},
	qr/The 'argument' parameter must be an arrayref/,
	"The 'argument' argument is mandatory.",
);

throws_ok(
	sub
	{
		App::GitHooks->new(
			arguments => [],
			name      => undef,
		);
	},
	qr/The argument 'name' is mandatory/,
	"The 'name' argument is mandatory.",
);


throws_ok(
	sub
	{
		App::GitHooks->new(
			arguments => [],
			name      => 'invalid-name',
		);
	},
	qr/Invalid hook name/,
	"The 'name' argument must be valid.",
);

my $app;
lives_ok(
	sub
	{
		$app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg',
		);
	},
	'Instantiate a new object with "arguments" specified.',
);

isa_ok(
	$app,
	'App::GitHooks',
);

lives_ok(
	sub
	{
		$app = App::GitHooks->new(
			arguments => undef,
			name      => 'commit-msg',
		);
	},
	'Instantiate a new object with no arguments specified.',
);
