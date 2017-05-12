#!perl -T

use strict;
use warnings;

use Carp::Parse::Redact;
use Data::Dump;
use Test::Exception;
use Test::More tests => 2;


my $stack_trace = do { local $/; <DATA> };
$stack_trace =~ s/^\s*//;
$stack_trace =~ s/\s*$//;

my $parsed_stack_trace;
lives_ok(
	sub
	{
		$parsed_stack_trace = Carp::Parse::Redact::parse_stack_trace(
			$stack_trace,
		);
	},
	'Parse test stack trace.',
);

my $expected_redacted_caller_information =
[
	[],
	[
		'Mr. Spock',
		'[redacted]',
		'12',
		'2012',
	],
	[],
	[ "CODE(0xb3d4f48)", "Try::Tiny::Finally=REF(0xaf503f0)" ],
];

subtest(
	'Sensitive information is redacted out.',
	sub
	{
		plan( tests => scalar( @$expected_redacted_caller_information ) );
		
		for ( my $i = 0; $i < scalar( @$expected_redacted_caller_information ); $i++ )
		{
			my $redacted_arguments_list = defined( $parsed_stack_trace->[$i] )
				? $parsed_stack_trace->[$i]->get_redacted_arguments_list()
				: undef;
			
			is_deeply(
				$redacted_arguments_list,
				$expected_redacted_caller_information->[$i],
				"The arguments for caller($i) are redacted out properly.",
			) || diag( Data::Dump::dump( $redacted_arguments_list ) );
		}
	},
);


__DATA__
Test.
at test/lib/Spock/test.t line 116
main::test_trace('Mr. Spock', '4111111111111111', '12', '2012') called at test/lib/Spock/test.t line 61
main::__ANON__() called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 76
eval {...} called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 67
Try::Tiny::try('CODE(0xb3d4f48)', 'Try::Tiny::Finally=REF(0xaf503f0)') called at test/lib/Spock/test.t line 69
