#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;

use lib 't/';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	),
	'Create a new Audit::DBI object.',
);

my $test_events_count = 3;
subtest(
	'Record test audit events.',
	sub
	{
		plan( tests => $test_events_count );

		foreach my $count ( 1 .. $test_events_count )
		{
			lives_ok(
				sub
				{
					$audit->record(
						event        => 'test_order_by',
						subject_type => 'test_subject',
						subject_id   => 'test_' . $count,
					);
				},
				"Write audit event $count.",
			);
		}
	},
);

my $tests =
[
	{
		name     => 'Retrieve audit events sorted by descending subject_id.',
		order_by =>
		[
			'subject_id' => 'DESC',
		],
		expected =>
		[
			map { "test_$_" } reverse ( 1 .. $test_events_count )
		],
	},
	{
		name     => 'Retrieve audit events sorted by ascending subject_id.',
		order_by =>
		[
			'subject_id' => 'ASC',
		],
		expected =>
		[
			map { "test_$_" } ( 1 .. $test_events_count )
		],
	},
];

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			ok(
				defined(
					my $audit_events = $audit->review(
						events   =>
						[
							{
								include => 1,
								event   => 'test_order_by',
							},
						],
						order_by => $test->{'order_by'},
					)
				),
				'Retrieve audit events.',
			);

			is(
				scalar( @$audit_events ),
				$test_events_count,
				'The count of audit events is correct.',
			);

			is_deeply(
				[ map { $_->{'subject_id'} } @$audit_events ],
				$test->{'expected'},
				'The events were correctly sorted by review().',
			) || diag( explain( $audit_events ) );
		}
	);
}
