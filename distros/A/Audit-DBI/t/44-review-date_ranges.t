#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use lib 't/';
use LocalTest;


my $test_event_times =
[
	1100000000, # Tue, 09 Nov 2004 11:33:20 GMT
	1201502189, # Mon, 28 Jan 2008 06:36:29 GMT
	1371502189, # Mon, 17 Jun 2013 20:49:49 GMT
];

my $tests =
[
	{
		name      => 'The upper date bound is respected.',
		input     =>
		[
			{
				begin     => 1,          # Thu, 01 Jan 1970 00:00:01 GMT
				end       => 1100000001, # Tue, 09 Nov 2004 11:33:21 GMT
				include   => 1,
			},
		],
		expected  =>
		[
			1100000000, # Tue, 09 Nov 2004 11:33:20 GMT
		],
	},
	{
		name      => 'Simple date range (2 results).',
		input     =>
		[
			{
				begin     => 900000000,  # Thu, 09 Jul 1998 16:00:00 GMT
				end       => 1201502190, # Mon, 28 Jan 2008 06:36:30 GMT
				include   => 1,
			},
		],
		expected  =>
		[
			1100000000, # Tue, 09 Nov 2004 11:33:20 GMT
			1201502189, # Mon, 28 Jan 2008 06:36:29 GMT
		],
	},
	{
		name      => 'Simple date range (3 results).',
		input     =>
		[
			{
				begin     => 900000000,  # Thu, 09 Jul 1998 16:00:00 GMT
				end       => 1471502189, # Thu, 18 Aug 2016 06:36:29 GMT
				include   => 1,
			},
		],
		expected  =>
		[
			1100000000, # Tue, 09 Nov 2004 11:33:20 GMT
			1201502189, # Mon, 28 Jan 2008 06:36:29 GMT
			1371502189, # Mon, 17 Jun 2013 20:49:49 GMT
		],
	},
	{
		name      => 'The lower date bound is respected.',
		input     =>
		[
			{
				begin     => 1100000001, # Tue, 09 Nov 2004 11:33:21 GMT
				end       => 1471502189, # Thu, 18 Aug 2016 06:36:29 GMT
				include   => 1,
			},
		],
		expected  =>
		[
			1201502189, # Mon, 28 Jan 2008 06:36:29 GMT
			1371502189, # Mon, 17 Jun 2013 20:49:49 GMT
		],
	},
	{
		name      => 'Check a large range.',
		input     =>
		[
			{
				begin     => 1,          # Thu, 01 Jan 1970 00:00:01 GMT
				end       => 1671502189, # Tue, 20 Dec 2022 02:09:49 GMT
				include   => 1,
			},
		],
		expected  =>
		[
			1100000000, # Tue, 09 Nov 2004 11:33:20 GMT
			1201502189, # Mon, 28 Jan 2008 06:36:29 GMT
			1371502189, # Mon, 17 Jun 2013 20:49:49 GMT
		],
	},
	{
		name      => 'Check a range with no results.',
		input     =>
		[
			{
				begin     => 1671502189, # Tue, 20 Dec 2022 02:09:49 GMT
				end       => 1771502189, # Thu, 19 Feb 2026 11:56:29 GMT
				include   => 1,
			},
		],
		expected  =>
		[],
	},
];

plan( tests => 3 + scalar( @$tests ) );

my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	),
	'Create a new Audit::DBI object.',
);

# Prepare test events.
my $event = 'test_event_times_' . time();
subtest(
	'Record test audit events.',
	sub
	{
		plan( tests => scalar( @$test_event_times ) );

		foreach my $event_time ( @$test_event_times )
		{
			lives_ok(
				sub
				{
					$ENV{'REMOTE_ADDR'} = $event_time;

					$audit->record(
						event        => $event,
						subject_type => 'test_subject',
						subject_id   => 'test_' . $event_time,
						event_time   => $event_time,
					);
				},
				"Write audit event with time $event_time.",
			);
		}
	},
);

# Run the tests.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			ok(
				defined(
					my $audit_events = $audit->review(
						date_ranges => $test->{'input'},
						events      =>
						[
							{
								include => 1,
								event   => $event,
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
				[ map { 'test_' . $_ } @{ $test->{'expected'} } ],
				'The events returned review() match expected results.',
			) || diag( explain( $audit_events ) );
		}
	);
}
