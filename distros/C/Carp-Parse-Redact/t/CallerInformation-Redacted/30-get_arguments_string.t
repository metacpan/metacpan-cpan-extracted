#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::More tests => 1;


my $TEST_ARGUMENTS_STRING = '( 1, 2, 3 )';

my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string => $TEST_ARGUMENTS_STRING,
		arguments_list   => [ 'Test' ],
		line             => 'Test at line X',
	}
);

is(
	$caller_information->get_arguments_string(),
	$TEST_ARGUMENTS_STRING,
	'get_arguments_string() returns the information used when setting up the object.',
);
