#!perl -T

use strict;
use warnings;

use Audit::DBI::TT2;
use Audit::DBI;
use DBI;
use POSIX qw();
use Scalar::Util;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 12;


# Check if POSIX::tzset() exists on the current architecture. Strawberry Perl
# in particular seems to be missing it.
eval { POSIX::tzset(); };
my $has_tzset = $@ ? 0 : 1;

# Some builds of Perl v.5.14.* and v5.16.* on Windows seem to have tzset(), but
# setting it does not actually change the timezone due to a bug. Fall back on
# the simpler test.
$has_tzset = 0
	if ( $^O eq 'MSWin32' ) && ( $^V =~ /^v5\.(?:14|16)\./ );

# Override the timezone to be able to format the event's date and have a
# consistent, testable output.
SKIP:
{
	skip(
		'POSIX::tzset() is not available, cannot set timezone.',
		1,
	) if !$has_tzset;

	lives_ok(
		sub
		{
			$ENV{'TZ'} = 'America/New_York';
			POSIX::tzset();
		},
		'Set timezone to America/New_York.',
	);
}

# Verify that the function can be called.
can_ok(
	'Audit::DBI::TT2',
	'format_results',
);

# Prepare a set of results to format.
use_ok( 'Audit::DBI::Event' );
ok(
	my $dbh = DBI->connect(
		'dbi:SQLite:dbname=:memory:',
		'',
		'',
		{
			RaiseError => 1,
		}
	),
	'Create connection to a database.',
);
ok(
	bless( $dbh, 'DBI::db::Test' ),
	'Override the class of the database connection for testing.',
);

# Create the audit object and generate an audit event.
ok(
	defined(
		my $audit = Audit::DBI->new(
			database_handle => $dbh,
		)
	),
	'Create an Audit::DBI object.',
);
ok(
	defined(
		my $audit_event = $audit->insert_event(
			{
				information =>
				{
					key1 => 'value1',
					key2 => 'value2',
				},
				diff        =>
				[
					'string1',
					'string2',
				],
				event_time  => 1347063261,
			}
		)
	),
	'Generated audit event with test data.',
);

my $results =
[
	$audit_event,
];

# Instantiate a template plugin object.
my $tt2 = Audit::DBI::TT2->new();

# Format the results.
my $output;
lives_ok(
	sub
	{
		# Use fixed indentation, to be able to compare the output.
		local $Data::Dumper::Indent = 1;

		$output = $tt2->format_results( $results );
	},
	'Format the results.',
);
is(
	Scalar::Util::refaddr( $output ),
	Scalar::Util::refaddr( $results ),
	'The formatted information was added to the original arrayref.',
);

# Verify the first event.
my $event = $results->[0];
is(
	$event->{'diff_formatted'},
	'{&nbsp;new&nbsp;=&gt;&nbsp;&quot;string2&quot;,&nbsp;old&nbsp;=&gt;&nbsp;&quot;string1&quot;&nbsp;}',
	'The diff is formatted correctly.',
);
is(
	$event->{'information_formatted'},
	'{&nbsp;key1&nbsp;=&gt;&nbsp;&quot;value1&quot;,&nbsp;key2&nbsp;=&gt;&nbsp;&quot;value2&quot;&nbsp;}',
	'The information is formatted correctly.',
);

# If we were able to set the timezone, we know the exact value to check for.
# Otherwise, depending on the timezone, we could end up with either 2012-09-07
# or 2012-09-08.
if ( $has_tzset )
{
	is(
		$event->{'event_time_formatted'},
		'2012-09-07 20:14:21',
		'The event time is formatted correctly.',
	);
}
else
{
	like(
		$event->{'event_time_formatted'},
		qr/^2012-09-0[78]/
	);
}


# Subclass DBI::db and override do() to make it inactive.
package DBI::db::Test;

use base 'DBI::db';

sub do
{
	return 1;
}

1;

