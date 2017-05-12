#!perl

use strict;
use warnings;

use App::GitHooks;
use App::GitHooks::Test;
use Capture::Tiny;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 3 );

# Force a clean githooks config to ensure repeatable test conditions.
App::GitHooks::Test::ok_reset_githooksrc(
	content => "force_plugins = Test\n"
		. "[testing]\n"
		. "force_is_utf8 = 0\n"
		. "force_use_colors = 0\n",
);

my $exit_status;
my $stdout = Capture::Tiny::capture_stdout(
	sub
	{
		$exit_status = App::GitHooks->run(
			name      => 'post-checkout',
			arguments => [],
			exit      => 0,  # Return the exit code instead of exiting.
		);
	}
);

is(
	$exit_status,
	1,
	'The hook reports a failure.',
) || note( "Exit status: $exit_status" );

if ( defined( $stdout ) && ( $stdout ne '' ) )
{
	note( "----- stdout -----" );
	note( $stdout );
	note( "------------------" );
}

like(
	$stdout,
	qr/x Test/,
	'The error is correctly trapped by the hook and printed out.',
);


# Test package with a post-checkout action.
package App::GitHooks::Plugin::Test;

use base 'App::GitHooks::Plugin';

use App::GitHooks::Constants qw( $PLUGIN_RETURN_PASSED );

sub run_post_checkout
{
	die "Test\n";
}

1;
