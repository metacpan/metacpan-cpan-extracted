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
	'new',
);

dies_ok(
	sub
	{
		App::GitHooks::CommitMessage->new(
			app     => undef,
			message => 'Test',
		);
	},
	'An "app" argument must be provided.',
);

dies_ok(
	sub
	{
		App::GitHooks::CommitMessage->new(
			app     => bless( {}, 'App::GitHooks'),
			message => undef,
		);
	},
	'A "message" argument must be provided.',
);

my $commit_message;
lives_ok(
	sub
	{
		$commit_message = App::GitHooks::CommitMessage->new(
			app     => bless( {}, 'App::GitHooks'),
			message => 'Test',
		);
	},
	'Instantiate a new CommitMessage object.',
);

isa_ok(
	$commit_message,
	'App::GitHooks::CommitMessage',
);
