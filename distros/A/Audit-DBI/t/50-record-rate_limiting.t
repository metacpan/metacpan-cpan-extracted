#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Config::Tiny;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use lib 't/';
use LocalTest;


# Verify if Cache::Memcached::Fast is installed.
eval 'use Cache::Memcached::Fast';
plan( skip_all => 'Cache::Memcached::Fast required to test rate limiting.' )
	if $@;

# Verify that memcache is configured and running.
my $memcache = Cache::Memcached::Fast->new(
	{
		servers =>
		[
			'localhost:11211',
		],
	}
);

plan( skip_all => 'Memcache is not running or configured on this machine, cannot test rate limiting' )
	if !defined( $memcache) || !$memcache->set( 'test_audit_dbi_key', 1, time() + 10 );

# Memcache is ready to use, start testing.
plan( tests => 10 );

my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
		memcache        => $memcache,
	),
	'Create a new Audit::DBI object.',
);

# Test data.
my $time = time();
my $test_event = 'Test audit event';
my $test_subject_type = 'test';
my $random_string = generate_random_string( 10 ) . $time;
my $limit_rate_timespan = 2;
my $limit_rate_subject_a = generate_random_string( 10 ) . $time;
my $limit_rate_subject_b = generate_random_string( 10 ) . $time;
my $limit_rate_subject_c = generate_random_string( 10 ) . $time;
my $limit_rate_unique_key = join( '_', $test_subject_type, $random_string, $time );

# Log audit event with rate-limit parameters.
lives_ok(
	sub
	{
		$audit->record(
			event                 => $test_event,
			subject_type          => $test_subject_type,
			subject_id            => $limit_rate_subject_a,
			limit_rate_timespan   => $limit_rate_timespan,
			limit_rate_unique_key => $limit_rate_unique_key,
			information           =>
			{
				test_id       => $limit_rate_subject_a,
				random_string => $random_string,
			},
			search_data           =>
			{
				test_id       => $limit_rate_subject_a,
				random_string => $random_string,
			},
		);
	},
	'Write audit event.',
);

# Log audit event again before cache expires.
lives_ok(
	sub
	{
		$audit->record(
			event                 => $test_event,
			subject_type          => $test_subject_type,
			subject_id            => $limit_rate_subject_b,
			limit_rate_timespan   => $limit_rate_timespan,
			limit_rate_unique_key => $limit_rate_unique_key,
			information           =>
			{
				test_id       => $limit_rate_subject_b,
				random_string => $random_string,
			},
			search_data           =>
			{
				test_id       => $limit_rate_subject_b,
				random_string => $random_string,
			},
		);
	},
	'Write audit event.',
);

# Wait until cache expires.
ok(
	sleep( $limit_rate_timespan + 2 ),
	'Wait until the rate-limit time allows logging this event again.',
);

# Log audit event again after cache expires.
lives_ok(
	sub
	{
		$audit->record(
			event                 => $test_event,
			subject_type          => $test_subject_type,
			subject_id            => $limit_rate_subject_c,
			limit_rate_timespan   => $limit_rate_timespan,
			limit_rate_unique_key => $limit_rate_unique_key,
			information           =>
			{
				test_id       => $limit_rate_subject_c,
				random_string => $random_string,
			},
			search_data           =>
			{
				test_id       => $limit_rate_subject_c,
				random_string => $random_string,
			},
		);
	},
	'Write audit event.',
);

# Read in audit events with matching subject_type and subject_id.
ok(
	defined(
		my $audit_events = $audit->review(
			subjects =>
			[
				{
					include => 1,
					type    => $test_subject_type,
					ids     =>
					[
						$limit_rate_subject_a,
						$limit_rate_subject_b,
						$limit_rate_subject_c,
					],
				},
			],
		)
	),
	'Retrieve audit records.',
);

is(
	scalar( @$audit_events ),
	2,
	'Find only two records matching the three unique subject IDs.',
)
||
diag(
	explain(
		{
			audit_events_retrieved => $audit_events,
			subject_a              => $limit_rate_subject_a,
			subject_b              => $limit_rate_subject_b,
			subject_c              => $limit_rate_subject_c,
		}
	)
);

# Verify that the random string for the first and last entry are found.
subtest(
	'Check that the non-rate-limited events were logged.',
	sub
	{
		plan( tests => 2 );

		is(
			scalar( grep { $_->{'subject_id'} eq $limit_rate_subject_a } @$audit_events ),
			1,
			"The subject ID >$limit_rate_subject_a< matches an event that was logged.",
		);

		is(
			scalar( grep { $_->{'subject_id'} eq $limit_rate_subject_c } @$audit_events ),
			1,
			"The subject ID >$limit_rate_subject_c< matches an event that was logged.",
		);
	},
) || diag( explain( $audit_events ) );

# Verify that the random string for the middle entry is not found.
subtest(
	'Check that the rate-limited events were not logged.',
	sub
	{
		plan( tests => 1 );

		is(
			scalar( grep { $_->{'subject_id'} eq $limit_rate_subject_b } @$audit_events ),
			0,
			"The subject ID >$limit_rate_subject_b< matches no logged event.",
		);
	},
);


sub generate_random_string
{
	my ( $length ) = @_;

	$length = 10
		unless defined( $length ) && $length > 0;

	my @char = ( 'a'..'z', 'A'..'Z', '0'..'9' );
	return join('', map { $char[ rand @char ] } ( 1 .. $length ) );
}

