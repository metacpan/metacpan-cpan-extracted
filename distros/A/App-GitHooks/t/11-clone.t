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
plan( tests => 5 );

can_ok(
	'App::GitHooks',
	'clone',
);

ok(
	defined(
		my $app = App::GitHooks->new(
			arguments => [],
			name      => 'commit-msg',
		)
	),
	'Instantiate a new App::GitHooks object.',
);

throws_ok(
	sub
	{
		$app->clone(
			invalid_argument => 1,
		);
	},
	qr/\QInvalid argument(s): invalid_argument/,
	'clone() rejects invalid arguments.',
);

# Test cloning without any overrides.
subtest(
	'Clone app object without overrides.',
	sub
	{
		plan( tests => 4 );

		# Clone.
		my $clone;
		lives_ok(
			sub
			{
				$clone = $app->clone();
			},
			'Clone the app object.',
		);

		# Make sure the clone has the correct class.
		isa_ok(
			$clone,
			'App::GitHooks',
		);

		# Make sure the objects match.
		is_deeply(
			$clone,
			$app,
			'The data structure is identical for the object and its clone.',
		) || diag( explain( "Object: ", $app, "Cloned object: ", $clone ) );

		# Make sure the objects don't point to the same memory location.
		isnt(
			$clone,
			$app,
			'The object and its clone point to different memory locations.',
		);
	}
);

# Test cloning with an override of the triggered hook name.
subtest(
	'Clone app object .',
	sub
	{
		plan( tests => 6 );

		# Override with a valid hook name only.
		throws_ok(
			sub
			{
				my $clone = $app->clone(
					name => 'test',
				);
			},
			qr/\QInvalid hook name test\E/,
			'Cloning the app object with an incorrect hook name is not allowed.',
		);

		# Clone with a valid but different hook name.
		my $clone;
		lives_ok(
			sub
			{
				$clone = $app->clone(
					name => 'prepare-commit-msg',
				);
			},
			'Clone the app object with name=prepare-commit-msg.',
		);

		# Make sure the clone has the correct class.
		isa_ok(
			$clone,
			'App::GitHooks',
		);

		# Make sure the hook name has been overriden.
		is(
			$clone->get_hook_name(),
			'prepare-commit-msg',
			'The hook name matches the override.',
		);

		# Make sure the objects don't point to the same memory location.
		isnt(
			$clone,
			$app,
			'The object and its clone point to different memory locations.',
		);

		# Make sure the objects match except for the hook name.
		{
			local $clone->{'hook_name'} = 'commit-msg';
			is_deeply(
				$clone,
				$app,
				'The data structure is identical for the object and its clone, except for the triggering hook name.',
			) || diag( explain( "Object: ", $app, "Cloned object: ", $clone ) );
		}
	}
);



