#!perl -T

use strict;
use warnings;

use Audit::DBI::Event;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


can_ok(
	'Audit::DBI::Event',
	'new',
);

throws_ok(
	sub
	{
		Audit::DBI::Event->new();
	},
	qr/\QThe parameter "data" is mandatory\E/,
	'The parameter "data" is mandatory.',
);

throws_ok(
	sub
	{
		Audit::DBI::Event->new(
			data => 'test',
		);
	},
	qr/\QThe parameter "data" must be a hashref\E/,
	'The parameter "data" must be a hashref.',
);

my $event;
lives_ok(
	sub
	{
		$event = Audit::DBI::Event->new(
			data => {},
		);
	},
	'Instantiate a new Audit::DBI::Event object.',
);

isa_ok(
	$event,
	'Audit::DBI::Event',
);
