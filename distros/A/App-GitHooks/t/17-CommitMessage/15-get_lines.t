#!perl

use strict;
use warnings;

use App::GitHooks::CommitMessage;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::Requires::Git;
use Test::More;


# Require git.
test_requires_git( '1.7.4.1' );

my $tests =
[
	{
		name                => 'summary and description',
		message             => "Test.\n\nThis is a test commit.\n#Test",
		lines               => [ 'Test.', 'This is a test commit.' ],
		include_comments    => 0,
		include_blank_lines => 0,
	},
	{
		name                => 'summary and description (keep comments)',
		message             => "Test.\n\nThis is a test commit.\n#Test",
		lines               => [ 'Test.', 'This is a test commit.', '#Test' ],
		include_comments    => 1,
		include_blank_lines => 0,
	},
	{
		name                => 'summary and description (keep blank lines)',
		message             => "Test.\n\nThis is a test commit.\n#Test",
		lines               => [ 'Test.', '', 'This is a test commit.' ],
		include_comments    => 0,
		include_blank_lines => 1,
	},
	{
		name                => 'summary and description (keep comments and blank lines)',
		message             => "Test.\n\nThis is a test commit.\n#Test",
		lines               => [ 'Test.', '', 'This is a test commit.', '#Test' ],
		include_comments    => 1,
		include_blank_lines => 1,
	},
	{
		name                => 'summary only',
		message             => "Test",
		lines               => [ 'Test' ],
		include_comments    => 0,
		include_blank_lines => 0,
	},
	{
		name                => 'trailing carriage return',
		message             => "Test.\n\nThis is a test commit.\n",
		lines               => [ 'Test.', 'This is a test commit.' ],
		include_comments    => 0,
		include_blank_lines => 0,
	},
	{
		name                => 'trailing carriage return',
		message             => "Test.\n\nThis is a test commit.\n\n",
		lines               => [ 'Test.', '', 'This is a test commit.' ],
		include_comments    => 0,
		include_blank_lines => 1,
	},
	{
		name                => 'leading carriage return',
		message             => "\n\nThis is a test commit.\n\n",
		lines               => [ '', '', 'This is a test commit.' ],
		include_comments    => 0,
		include_blank_lines => 1,
	},
];

plan( tests => scalar( @$tests ) + 1 );

can_ok(
	'App::GitHooks::CommitMessage',
	'get_lines',
);

foreach my $test ( @$tests )
{
	subtest(
		"Test getting the commit message lines - $test->{'name'}.",
		sub
		{
			note( "include_comments=$test->{'include_comments'}, include_blank_lines=$test->{'include_blank_lines'}" );

			ok(
				defined(
					my $commit_message = App::GitHooks::CommitMessage->new(
						app     => bless( {}, 'App::GitHooks' ),
						message => $test->{'message'},
					)
				),
				'Instantiate a new CommitMessage object.',
			);

			my $result = $commit_message->get_lines(
				include_comments    => $test->{'include_comments'},
		    include_blank_lines => $test->{'include_blank_lines'},
			);
			is_deeply(
				$result,
				$test->{'lines'},
				'get_lines() returns the message originally provided.',
			) || diag( 'Got: ', explain( $result ) ) ;
		}
	);
}
