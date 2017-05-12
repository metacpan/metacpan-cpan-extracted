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


eval "use Math::Currency";
plan( skip_all => "Math::Currency required for testing stringification." )
    if $@;

plan( tests => 8 );

my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	),
	'Create a new Audit::DBI object.',
);

ok(
	defined(
		my $currency = Math::Currency->new( '10.99', 'en_US' )
	),
	'Create a stringifiable object.',
);

ok(
	$Audit::DBI::FORCE_OBJECT_STRINGIFICATION =
	{
		'Math::Currency' => 'bstr',
	},
	'Set the map of stringifiable objects.',
);

my $time = time();

lives_ok(
	sub
	{
		$audit->record(
			event        => 'test_stringification',
			subject_type => 'stringification',
			subject_id   => $time,
			diff         =>
			[
				'$0',
				$currency,
			],
			information  =>
			{
				currency => $currency,
			},
		);
	},
	'Write audit event.',
);

ok(
	defined(
		my $audit_events = $audit->review(
			subjects =>
			[
				{
					include => 1,
					type    => 'stringification',
					ids     =>
					[
						$time,
					],
				},
			],
		)
	),
	'Retrieve audit records.',
);

my $audit_event = $audit_events->[0];

my $diff = $audit_event->get_diff();
is_deeply(
	$diff,
	{
		'new' => '$10.99',
		'old' => '$0'
	},
	'The diff is stringified.',
) || diag( explain( $diff ) );

my $information = $audit_event->get_information();
is_deeply(
	$information,
	{
		'currency' => '$10.99'
	},
	'The information is stringified.',
) || diag( explain( $information ) );

