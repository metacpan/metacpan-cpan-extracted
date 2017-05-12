#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Test::Exception;
use Test::Requires::Git;;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


# Require git.
test_requires_git( '1.7.4.1' );

## no critic (RegularExpressions::RequireExtendedFormatting)

# Test files.
my $files =
{
	'test.pl' => "#!perl\n\nuse strict;\n",
};

# Plugin configuration options.
my $env_variable = 'test_environment';

# Regex to detect when the plugin has identified a commit in production.
my $failure = qr/x Non-dev environment detected - please commit from your dev instead/;

# Bail out if Git isn't available.
test_requires_git();
plan( tests => 4 );

my $repository = ok_setup_repository(
	cleanup_test_repository => 1,
	config                  => "",
	hooks                   => [ 'pre-commit' ],
	plugins                 => [ 'BlockProductionCommits' ],
);

# Set up test files.
ok_add_files(
	files      => $files,
	repository => $repository,
);

# Try to commit.
my $stderr;
lives_ok(
	sub
	{
		$stderr = Capture::Tiny::capture_stderr(
			sub
			{
				$repository->run( 'commit', '-m', 'Test message.' );
			}
		);
		note( $stderr );
	},
	'Commit the changes.',
);

like(
	$stderr,
	qr/\QYou must define 'env_variable' in the [BlockProductionCommits] section of your githooksrc config\E/,
	"The output matches expected results.",
);
