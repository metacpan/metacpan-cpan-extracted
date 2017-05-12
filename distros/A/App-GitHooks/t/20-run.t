#!perl

use strict;
use warnings;

use App::GitHooks;
use Capture::Tiny;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 4 );

can_ok(
	'App::GitHooks',
	'run',
);

ok(
	defined(
		my $app = App::GitHooks->new(
			name      => 'commit-msg',
			arguments => [],
		)
	),
	'Create a new App::GitHooks object.',
);

my $exit_status;
my $stderr = Capture::Tiny::capture_stderr(
	sub
	{
		$exit_status = $app->run(
			invalid_argument => 'test',
			exit             => 0,
		);
	}
);
note( $stderr );

like(
	$stderr,
	qr/\QError detected in hook: \E/,
	'Invalid arguments are detected.',
);

is(
	$exit_status,
	1,
	'The exit status correctly indicates an error.',
);
