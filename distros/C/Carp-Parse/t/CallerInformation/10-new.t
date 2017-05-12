#!perl -T

use strict;
use warnings;

use Carp::Parse::CallerInformation;
use Test::More tests => 7;
use Test::Exception;

dies_ok(
	sub
	{
		my $caller_information = Carp::Parse::CallerInformation->new();
	},
	'A data hashref is required.'
);

lives_ok(
	sub
	{
		my $caller_information = Carp::Parse::CallerInformation->new(
			{
				arguments_list   => [ 'Test' ],
				line             => 'Test at line X',
			}
		);
	},
	"'arguments_string' is a required data.",
);

lives_ok(
	sub
	{
		my $caller_information = Carp::Parse::CallerInformation->new(
			{
				arguments_string => 'Test',
				line             => 'Test at line X',
			}
		);
	},
	"'arguments_list' is not a required data.",
);

dies_ok(
	sub
	{
		my $caller_information = Carp::Parse::CallerInformation->new(
			{
				arguments_string => 'Test',
				arguments_list   => [ 'Test' ],
			}
		);
	},
	"'line' is a required data.",
);

my $caller_information;
lives_ok(
	sub
	{
		$caller_information = Carp::Parse::CallerInformation->new(
			{
				arguments_string => 'Test',
				arguments_list   => [ 'Test' ],
				line             => 'Test at line X',
			}
		);
	},
	'Create a Carp::Parse::CallerInformation object with valid arguments.',
);

ok(
	defined( $caller_information ),
	'The object is defined.',
);

isa_ok(
	$caller_information,
	'Carp::Parse::CallerInformation',
	'$caller_information',
);