#!perl

use strict;
use warnings;

use App::GitHooks::CommitMessage;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );
plan( tests => 5 );

can_ok(
	'App::GitHooks::CommitMessage',
	'update_message',
);


ok(
	defined(
		my $commit_message = App::GitHooks::CommitMessage->new(
			app => bless( {}, 'App::GitHooks' ),
			message => 'Test 1.',
		)
	),
	'Instantiate a new CommitMessage object.',
);

is(
	$commit_message->get_message(),
	'Test 1.',
	'get_message() returns the value passed on creation.',
);

lives_ok(
	sub
	{
		$commit_message->update_message( 'Test 2.' );
	},
	'Update the commit message.',
);

is(
	$commit_message->get_message(),
	'Test 2.',
	'get_message() returns the updated value.',
);
