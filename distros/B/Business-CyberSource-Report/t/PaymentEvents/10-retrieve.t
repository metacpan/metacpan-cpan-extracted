#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report::PaymentEvents;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::LWP::UserAgent;
use Test::More;


my $tests =
[
	# Test 'format' argument.
	{
		name   => "The 'format' argument is mandatory.",
		args   =>
		{
			date   => '2013/06/30',
		},
		throws => qr/\QThe format needs to be 'csv' or 'xml'\E/,
	},
	{
		name   => "The 'format' argument recognizes 'csv'.",
		args   =>
		{
			date   => '2013/06/30',
			format => 'csv',
		},
	},
	{
		name   => "The 'format' argument recognizes 'xml'.",
		args   =>
		{
			date   => '2013/06/30',
			format => 'xml',
		},
	},
	{
		name   => "The 'format' argument does not recognize invalid formats.",
		args   =>
		{
			date   => '2013/06/30',
			format => 'test',
		},
		throws => qr/\QThe format needs to be 'csv' or 'xml'\E/,
	},

	# Test 'date' argument.
	{
		name   => "The 'date' argument is mandatory.",
		args   =>
		{
			format => 'csv',
		},
		throws => qr/\QYou need to specify a date for the transactions to retrieve\E/,
	},
	{
		name   => "The 'date' argument must be correctly formatted.",
		args   =>
		{
			date   => '20130630',
			format => 'csv',
		},
		throws => qr|\QThe format for the date of the transactions to retrieve is YYYY/MM/DD\E|,
	},
	{
		name   => "The 'date' argument recognizes properly formatted dates.",
		args   =>
		{
			date   => '2013/06/30',
			format => 'csv',
		},
	},
];

plan( tests => 4 + scalar( @$tests ) );

ok(
	Business::CyberSource::Report::PaymentEvents->can( 'retrieve' ),
	'A "retrieve" function exists.',
);

lives_ok(
	sub
	{
		Test::LWP::UserAgent->map_response(
			qr/\Qcybersource.com\E/,
			HTTP::Response->new( '200' ),
		),
	},
	'Re-route requests to CyberSource.',
);

ok(
	defined(
		my $report_factory = Business::CyberSource::Report->new(
			merchant_id => 'test_merchant',
			username    => 'test_username',
			password    => 'test_password',
		)
	),
	'Create a Business::CyberSource::Report object.',
);

ok(
	defined(
		my $payment_events_report = $report_factory->build( 'PaymentEvents' )
	),
	'Build a Business::CyberSource::Report::PaymentEvents object.',
);

foreach my $test ( @$tests )
{
	if ( defined( $test->{'throws'} ) )
	{
		throws_ok(
			sub
			{
				$payment_events_report->retrieve(
					%{ $test->{'args'} },
					user_agent => Test::LWP::UserAgent->new(),
				);
			},
			$test->{'throws'},
			$test->{'name'},
		);
	}
	else
	{
		lives_ok(
			sub
			{
				$payment_events_report->retrieve(
					%{ $test->{'args'} },
					user_agent => Test::LWP::UserAgent->new(),
				);
			},
			$test->{'name'},
		);
	}
}
