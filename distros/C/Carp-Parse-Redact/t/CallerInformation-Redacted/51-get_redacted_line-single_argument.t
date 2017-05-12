#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation::Redacted;
use Test::More tests => 1;


my $caller_information = Carp::Parse::CallerInformation::Redacted->new(
	{
		arguments_string        => "'batman'",
		arguments_list          =>
		[
			'batman',
		],
		redacted_arguments_list =>
		[
			'batman',
		],
		line                    => "answer_bat_signal('batman')",
	}
);

is(
	$caller_information->get_redacted_line(),
	'answer_bat_signal("batman")',
	'get_redacted_line() handles single arguments correctly.',
);
