#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::More tests => 1;


my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string        => "'username', 'batman', 'test', '1'",
		arguments_list          =>
		[
			'username',
			'batman',
			'test',
			'1',
		],
		redacted_arguments_list =>
		[
			'username',
			'[redacted]',
			'test',
			'1',
		],
		line                    => "answer_bat_signal('username', 'batman', 'test', '1')",
	}
);

is(
	$caller_information->get_redacted_line(),
	'answer_bat_signal("username", "[redacted]", "test", 1)',
	'get_redacted_line() returns the redacted version of the original line.',
);
