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
						event        => 'test_review_values',
						subject_type => 'test_subject',
						subject_id   => 'test_' . $count,
						search_data  =>
						{
							key => '123',
						}
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
		name      => 'Retrieve audit events indexed with key=123.',
		index_key => '123',
		expected  =>
		[
			map { "test_$_" } ( 1 .. $test_events_count )
		],
	},
	{
		name      => 'Retrieve audit events indexed with key=456.',
		index_key => '456',
		expected  => [],
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
						values =>
						[
							{
								include => 1,
								name    => 'key',
								values  => [ $test->{'index_key'} ],
							},
						],
					)
				),
				'Retrieve audit events.',
			);

			is(
				scalar( @$audit_events ),
				scalar( @{ $test->{'expected'} } ),
				'The count of audit events is correct.',
			);

			is_deeply(
				[ map { $_->{'subject_id'} } @$audit_events ],
				$test->{'expected'},
				'The events returned review() match expected results.',
			) || diag( explain( $audit_events ) );
		}
	);
}
