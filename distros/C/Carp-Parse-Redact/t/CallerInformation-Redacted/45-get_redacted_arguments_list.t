#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::More tests => 1;


my $TEST_REDACTED_ARGUMENTS_LIST =
[
	'username',
	'[redacted]',
	'test',
	'1',
];

my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string        => '1, 2, 3',
		arguments_list          => [ 'Test' ],
		redacted_arguments_list => $TEST_REDACTED_ARGUMENTS_LIST,
		line                    => 'Test at line X',
	}
);

is(
	$caller_information->get_redacted_arguments_list(),
	$TEST_REDACTED_ARGUMENTS_LIST,
	'get_redacted_arguments_list() returns the information used when setting up the object.',
);
