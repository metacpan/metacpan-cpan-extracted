#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::More tests => 1;


my $TEST_LINE = 'Test at line X';

my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string => 'Test',
		arguments_list   => [ 'Test' ],
		line             => $TEST_LINE,
	}
);

is(
	$caller_information->get_line(),
	$TEST_LINE,
	'get_line() returns the information used when setting up the object.',
);
