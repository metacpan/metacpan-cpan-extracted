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
	'has_changed',
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

ok(
	!$commit_message->has_changed(),
	'The commit message has not been changed.',
);

ok(
	$commit_message->update_message( 'Test 2.' ),
	'Update the commit message.',
);

ok(
	$commit_message->has_changed(),
	'The commit message has been changed.',
);
