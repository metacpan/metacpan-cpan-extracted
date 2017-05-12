#!perl -T

use strict;
use warnings;

use Carp::Parse;
use Test::Exception;
use Test::More tests => 2;


my $stack_trace = do { local $/; <DATA> };
$stack_trace =~ s/^\s*//;
$stack_trace =~ s/\s*$//;

my $parsed_stack_trace;
lives_ok(
	sub
	{
		$parsed_stack_trace = Carp::Parse::parse_stack_trace( $stack_trace );
	},
	'Parse test stack trace.',
);

#use Data::Dump;
#print Data::Dump::dump( $parsed_stack_trace );

is_deeply(
	$parsed_stack_trace,
	[
		bless(
			{
				arguments_list   => undef,
				arguments_string => undef,
				line             => "Test.\nat test/lib/Spock/test.t line 116\n",
			},
			'Carp::Parse::CallerInformation',
		),
		bless(
			{
				arguments_list   =>
				[
					'[incorrect arguments format]',
				],
				arguments_string => "'gift_message\", \"Happy\\x{a}Birthday\\x{a}\\x{9}Love,\\x{a}\\x{9}Timmy\", \"password\", \"thereisnotry\", \"planet\", \"degobah\", \"ship_zip\", 01138, \"username\", \"yoda\"",
				line             => "main::test_trace('gift_message\", \"Happy\\x{a}Birthday\\x{a}\\x{9}Love,\\x{a}\\x{9}Timmy\", \"password\", \"thereisnotry\", \"planet\", \"degobah\", \"ship_zip\", 01138, \"username\", \"yoda\") called at test/lib/Spock/test.t line 61",
			},
			'Carp::Parse::CallerInformation',
		),
		bless(
			{
				arguments_list   => [],
				arguments_string => "",
				line             => "main::__ANON__() called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 76",
			},
			'Carp::Parse::CallerInformation',
		),
		bless(
			{
				arguments_list   =>
				[
					"CODE(0xb3d4f48)",
					"Try::Tiny::Finally=REF(0xaf503f0)",
				],
				arguments_string => "\"CODE(0xb3d4f48)\", \"Try::Tiny::Finally=REF(0xaf503f0)\"",
				line             => "Try::Tiny::try(\"CODE(0xb3d4f48)\", \"Try::Tiny::Finally=REF(0xaf503f0)\") called at test/lib/Spock/test.t line 69",
			},
			'Carp::Parse::CallerInformation',
		),
	],
	'The parsed stack trace matches the expected output.'
);


__DATA__
Test.
at test/lib/Spock/test.t line 116
main::test_trace('gift_message", "Happy\x{a}Birthday\x{a}\x{9}Love,\x{a}\x{9}Timmy", "password", "thereisnotry", "planet", "degobah", "ship_zip", 01138, "username", "yoda") called at test/lib/Spock/test.t line 61
main::__ANON__() called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 76
eval {...} called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 67
Try::Tiny::try("CODE(0xb3d4f48)", "Try::Tiny::Finally=REF(0xaf503f0)") called at test/lib/Spock/test.t line 69
