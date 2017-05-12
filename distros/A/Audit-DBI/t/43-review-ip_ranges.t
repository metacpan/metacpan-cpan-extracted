#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use lib 't/';
use LocalTest;


my $test_ip_addresses =
[
	'192.168.10.1',
	'192.168.100.1',
	'192.168.254.1',
];

my $tests =
[
	{
		name      => 'The upper IP bound is respected.',
		input     =>
		[
			{
				begin     => '192.168.1.1',
				end       => '192.168.50.1',
				include   => 1,
			},
		],
		expected  =>
		[
			'192.168.10.1',
		],
	},
	{
		name      => 'Simple IP range (2 results).',
		input     =>
		[
			{
				begin     => '192.168.1.1',
				end       => '192.168.250.1',
				include   => 1,
			},
		],
		expected  =>
		[
			'192.168.10.1',
			'192.168.100.1',
		],
	},
	{
		name      => 'Simple IP range (3 results).',
		input     =>
		[
			{
				begin     => '192.168.1.1',
				end       => '192.168.254.254',
				include   => 1,
			},
		],
		expected  =>
		[
			'192.168.10.1',
			'192.168.100.1',
			'192.168.254.1',
		],
	},
	{
		name      => 'The lower IP bound is respected.',
		input     =>
		[
			{
				begin     => '192.168.200.1',
				end       => '192.168.254.1',
				include   => 1,
			},
		],
		expected  =>
		[
			'192.168.254.1',
		],
	},
	{
		name      => 'Check a large range.',
		input     =>
		[
			{
				begin     => '192.1.1.1',
				end       => '193.1.1.1',
				include   => 1,
			},
		],
		expected  =>
		[
			'192.168.10.1',
			'192.168.100.1',
			'192.168.254.1',
		],
	},
	{
		name      => 'Check a range with no results.',
		input     =>
		[
			{
				begin     => '193.1.1.1',
				end       => '194.1.1.1',
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
my $event = 'test_ip_' . time();
subtest(
	'Record test audit events.',
	sub
	{
		plan( tests => scalar( @$test_ip_addresses ) );

		foreach my $ip_address ( @$test_ip_addresses )
		{
			lives_ok(
				sub
				{
					$ENV{'REMOTE_ADDR'} = $ip_address;

					$audit->record(
						event        => $event,
						subject_type => 'test_subject',
						subject_id   => 'test_' . $ip_address,
					);
				},
				"Write audit event with IP $ip_address.",
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
						ip_ranges => $test->{'input'},
						events    =>
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
