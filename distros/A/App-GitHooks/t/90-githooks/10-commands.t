#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::FailWarnings -allow_deps => 1;
use Test::Git;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );

# Declare tests.
my $tests =
[
	{
		name        => 'Call "githooks" with no arguments.',
		arguments   => [],
		expected    => qr/\QSetup utility for App::GitHooks.\E/,
		hooks_exist => 0,
	},
	{
		name        => 'Call "githooks help".',
		arguments   => [ 'help' ],
		expected    => qr/\QSetup utility for App::GitHooks.\E/,
		hooks_exist => 0,
	},
	{
		name        => 'Call "githooks version".',
		arguments   => [ 'version' ],
		expected    => qr/\QUsing App::GitHooks version \E\d+\.\d+\.\d+\./,
		hooks_exist => 0,
	},
	{
		name        => 'Verify that incorrect commands generate an error.',
		arguments   => [ 'invalid_command' ],
		expected    => qr/\QThe action 'invalid_command' is not valid.\E/,
		hooks_exist => 0,
	},
	{
		name        => 'Install git hooks.',
		arguments   => [ 'install' ],
		expected    => qr/\QThe git hooks have been installed successfully.\E/,
		hooks_exist => 1,
	},
	{
		name        => 'Uninstall git hooks.',
		arguments   => [ 'uninstall' ],
		expected    => qr/\QThe git hooks have been uninstalled successfully.\E/,
		hooks_exist => 0,
	},
];

plan( tests => scalar( @$tests ) + 4 );

# Set up test repository.
ok(
	defined(
		my $source_directory = Cwd::getcwd(),
	),
	'Retrieve the current directory.',
);

ok(
	defined(
		my $repository = test_repository()
	),
	'Create a test git repository.',
);

ok(
	chdir $repository->work_tree(),
	'Switch the current directory to the test git repository.',
);

# Execute tests.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 5 );
			ok(
				defined(
					my $command = System::Command->new(
						# Specify explicitly which Perl to use, to prevent conflicts
						# between the system Perl, /usr/bin/env perl, and others specified
						# by smoke testers.
						$^X,
						# Make sure we have the same includes as the parents, or we may
						# miss some of the dependencies installed for testing.
						( map { "-I$_" } @INC ),
						# The script to test.
						File::Spec->catfile( $source_directory, 'bin', 'githooks' ),
						# The arguments to pass to the script.
						@{ $test->{'arguments'} }
					)
				),
				'Execute "githooks".',
			);

			my $stderr = do { local $/; my $fh = $command->stderr(); <$fh> };
			ok(
				!defined( $stderr ) || ( $stderr eq '' ),
				'The command did not return any errors.',
			) || diag( $stderr );

			my $stdout = do { local $/; my $fh = $command->stdout(); <$fh> };
			ok(
				defined( $stdout ),
				'Capture the standard output.',
			);

			like(
				$stdout,
				$test->{'expected'},
				'Test output.',
			) || diag( $stdout );

			my $commit_hook_path = File::Spec->catfile( $repository->git_dir(), 'hooks', 'pre-commit' );
			if ( $test->{'hooks_exist'} )
			{
				ok(
					-e $commit_hook_path,
					'The commit hook exists.',
				);
			}
			else
			{
				ok(
					! -e $commit_hook_path,
					'The commit hook does not exist.',
				);
			}
		}
	);
}

# Restore working directory.
ok(
	chdir $source_directory,
	'Switch the current directory back to the original directory.',
);
