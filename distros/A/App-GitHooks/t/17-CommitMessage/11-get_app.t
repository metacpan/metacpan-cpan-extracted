#!perl

use strict;
use warnings;

use App::GitHooks::CommitMessage;
use Scalar::Util qw();
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 4 );

ok(
	defined(
		my $app = bless( {}, 'App::GitHooks')
	),
	'Create mockup App::GitHooks object.',
);

ok(
	defined(
		my $commit_message = App::GitHooks::CommitMessage->new(
			app     => $app,
			message => 'Test',
		),
	),
	'Instantiate a new object.',
);

my $retrieved_app;
lives_ok(
	sub
	{
		$retrieved_app = $commit_message->get_app();
	},
	'Retrieve the app instance with get_app().',
);

is(
	Scalar::Util::refaddr( $app ),
	Scalar::Util::refaddr( $retrieved_app ),
	'The object retrieved is the same as the object passed as parameter to new().',
);
