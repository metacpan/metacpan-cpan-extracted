#!perl -T

use strict;
use warnings;

use Audit::DBI::Event;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'Audit::DBI::Event',
	'get_id',
);

ok(
	defined(
		my $event = Audit::DBI::Event->new(
			data =>
			{
				audit_event_id => 15,
			},
		)
	),
	'Instantiate a new object.',
);

my $event_id;
lives_ok(
	sub
	{
		$event_id = $event->get_id();
	},
	'Retrieve the event ID.',
);

is(
	$event_id,
	15,
	'The event ID retrieved matches the event ID set on the object.',
);
