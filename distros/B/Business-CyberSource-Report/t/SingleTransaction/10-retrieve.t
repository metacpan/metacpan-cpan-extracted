#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report::SingleTransaction;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::LWP::UserAgent;
use Test::More;


my $tests =
[
	# Test 'request_id' argument.
	{
		name   => "Successful request using 'request_id'.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.7',
			include_extended_detail => 'Predecessor',
		},
	},
	{
		name   => "Either 'request_id' or a combination of 'merchant_reference_number' and 'target_date' is required.",
		args   =>
		{
			version                 => '1.7',
			include_extended_detail => 'Predecessor',
		},
		throws => qr/\A\QPlease provide either a request_id or the combination of a merchant_reference_number and target_date parameters\E/,
	},

	# Test 'merchant_reference_number' and 'target_date' arguments.
	{
		name   => "Successful request using a combination of 'merchant_reference_number' and 'target_date'.",
		args   =>
		{
			merchant_reference_number => '123456789',
			target_date               => '20130630',
			version                   => '1.7',
			include_extended_detail   => 'Predecessor',
		},
	},
	{
		name   => "Missing 'merchant_reference_number' with 'target_date'.",
		args   =>
		{
			target_date               => '20130630',
			version                   => '1.7',
			include_extended_detail   => 'Predecessor',
		},
		throws => qr/\A\QPlease provide either a request_id or the combination of a merchant_reference_number and target_date parameters\E/,
	},
	{
		name   => "Missing 'target_date' with 'merchant_reference_number'.",
		args   =>
		{
			merchant_reference_number => '123456789',
			version                   => '1.7',
			include_extended_detail   => 'Predecessor',
		},
		throws => qr/\A\QPlease provide either a request_id or the combination of a merchant_reference_number and target_date parameters\E/,
	},
	{
		name   => "The 'target_date' argument must be properly formatted.",
		args   =>
		{
			merchant_reference_number => '123456789',
			target_date               => '2013/06/30',
			version                   => '1.7',
			include_extended_detail   => 'Predecessor',
		},
		throws => qr/\A\QThe target_date format must be YYYYMMDD\E/,
	},

	# Test 'version' argument.
	{
		name   => "The 'version' argument must be valid.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => 'test',
			include_extended_detail => 'Predecessor',
		},
		throws => qr/\A\QThe version number can only be\E/,
	},

	# Test 'include_extended_detail' argument.
	{
		name   => "The 'include_extended_detail' argument is optional.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.7',
		},
	},
	{
		name   => "The 'include_extended_detail' argument accepts 'Related'.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.7',
			include_extended_detail => 'Related',
		},
	},
	{
		name   => "The 'include_extended_detail' argument accepts 'Predecessor'.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.7',
			include_extended_detail => 'Predecessor',
		},
	},
	{
		name   => "The 'include_extended_detail' argument does not accept invalid values.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.7',
			include_extended_detail => 'Invalid',
		},
		throws => qr/\A\QThe value of 'include_extended_detail' needs to be either 'Predecessor' or 'Related'\E/,
	},
	{
		name   => "The 'include_extended_detail' argument is only available after v1.3.",
		args   =>
		{
			request_id              => '12345678901234567890',
			version                 => '1.2',
			include_extended_detail => 'Predecessor',
		},
		throws => qr/\A\Q'include_extended_detail' is only available for versions >= 1.3\E/,
	},

];

plan( tests => 4 + scalar( @$tests ) );

ok(
	Business::CyberSource::Report::SingleTransaction->can( 'retrieve' ),
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
		my $payment_events_report = $report_factory->build( 'SingleTransaction' )
	),
	'Build a Business::CyberSource::Report::SingleTransaction object.',
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
