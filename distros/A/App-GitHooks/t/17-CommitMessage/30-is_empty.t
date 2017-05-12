#!perl

use strict;
use warnings;

use App::GitHooks::CommitMessage;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );

my $tests =
[
	{
		name     => 'summary and description',
		message  => "Test.\n\nThis is a test commit.",
		expected => 0,
	},
	{
		name     => 'summary only',
		message  => "Test",
		expected => 0,
	},
	{
		name     => 'comments only',
		message  => "# Some comment.\n#More comments.",
		expected => 1
	},
	{
		name     => 'empty lines only',
		message  => "\n\n\n",
		expected => 1,
	},
];

plan( tests => scalar( @$tests ) + 1 );

can_ok(
	'App::GitHooks::CommitMessage',
	'is_empty',
);

foreach my $test ( @$tests )
{
	subtest(
		"Test whether the commit message is empty - $test->{'name'}.",
		sub
		{
			ok(
				defined(
					my $commit_message = App::GitHooks::CommitMessage->new(
						app     => bless( {}, 'App::GitHooks' ),
						message => $test->{'message'},
					)
				),
				'Instantiate a new CommitMessage object.',
			);

			is(
				$commit_message->is_empty(),
				$test->{'expected'},
				'is_empty() returns the expected result.',
			);
		}
	);
}
