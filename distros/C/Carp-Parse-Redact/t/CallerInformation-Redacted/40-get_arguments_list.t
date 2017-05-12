#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::Deep;
use Test::More tests => 1;


my $TEST_ARGUMENTS_LIST = [ 1, 2, 3 ];

my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string => 'Test',
		arguments_list   => $TEST_ARGUMENTS_LIST,
		line             => 'Test at line X',
	}
);

is_deeply(
	$caller_information->get_arguments_list(),
	$TEST_ARGUMENTS_LIST,
	'get_arguments_list() returns the information used when setting up the object.',
);
