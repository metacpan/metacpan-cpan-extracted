#!perl

# The purpose of this test is to make sure that git actions with a dash in
# their name (such as post-checkout) are correctly triggering the run_<git
# action> subroutine in relevant plugins. Since Perl doesn't allow dashes in
# subroutine names, we need to convert those to underscores before calling
# run_<git_action>, and this test verifies that this conversion correctly takes
# place.
#
# IMPORTANT:
#
# We are using post-checkout here as our git action for testing, because the
# App::GitHooks::Hook::PostCheckout just inherits the generic run() method from
# its parent class App::Githooks::Hook. This allows testing the generic run()
# method, unlike App::GitHooks::Hook::CommitMsg (for example) which has its own
# custom run() method.
#
# This means that if we ever implement a custom run() subroutine for
# App::GitHooks::Hook::PostCheckout, we will need to change this test to use a
# different git action that:
#     - still triggers the generic run() in App::Githooks::Hook;
#     - has a dash in its name.

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
	content => "force_plugins = Test\n",
);

my $exit_status;
my $stderr = Capture::Tiny::capture_stderr(
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
	0,
	'The hook ran successfully.',
) || note( "Exit status: $exit_status" );

if ( defined( $stderr ) && ( $stderr ne '' ) )
{
	note( "----- stderr -----" );
	note( $stderr );
	note( "------------------" );
}

# If dashes in hook names were not properly replaced to find the subroutine
# name, the following error should show:
#
#     Can't locate object method "run_post-checkout" via package
#     "App::GitHooks::Plugin::Test"

unlike(
	$stderr,
	qr/run_post-checkout/,
	'The subroutine name was correctly determined from the hook name.',
);


# Test package with a post-checkout action.
package App::GitHooks::Plugin::Test;

use base 'App::GitHooks::Plugin';

use App::GitHooks::Constants qw( $PLUGIN_RETURN_PASSED );

sub run_post_checkout
{
	return $PLUGIN_RETURN_PASSED;
}

1;
