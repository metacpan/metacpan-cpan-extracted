#!perl -T

use strict;
use warnings;

use Carp::Parse::Redact;
use Data::Dump;
use Test::Exception;
use Test::More tests => 2;


# The test stack trace, along with the indentation of callers.
my $stack_trace = q|Test at test/lib/Spock/test.t line 116
        main::test_trace('gift_message', 'Happy Birthday from Timmy', 'password', 'thereisnotry', 'planet', 'degobah', 'ship_zip', 01138, 'username', 'yoda') called at test/lib/Spock/test.t line 61
        main::__ANON__() called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 76
        eval {...} called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 67
        Try::Tiny::try('CODE(0xb3d4f48)', 'Try::Tiny::Finally=REF(0xaf503f0)') called at test/lib/Spock/test.t line 69
|;

# The expected redacted lines.
# Note: tabs are for formatting of this array only, they are removed before
# comparing expected vs output.
my $expected_redacted_lines =
[
	q|Test at test/lib/Spock/test.t line 116|,
	q|        main::test_trace(
		          "gift_message",
		          "Happy Birthday from Timmy",
		          "password",
		          "[redacted]",
		          "planet",
		          "degobah",
		          "ship_zip",
		          "[redacted]",
		          "username",
		          "[redacted]",
		        ) called at test/lib/Spock/test.t line 61|,
	q|        main::__ANON__() called at /home/spock/site_perl/5.14.2/Try/Tiny.pm line 76|,
	q|        Try::Tiny::try("CODE(0xb3d4f48)", "Try::Tiny::Finally=REF(0xaf503f0)") called at test/lib/Spock/test.t line 69|,
];

my $parsed_stack_trace;
lives_ok(
	sub
	{
		$parsed_stack_trace = Carp::Parse::Redact::parse_stack_trace(
			$stack_trace,
			sensitive_argument_names =>
			[
				'password',
				'username',
				'ship_zip',
			],
		);
	},
	'Parse test stack trace.',
);

subtest(
	'Sensitive information is redacted out.',
	sub
	{
		plan( tests => scalar( @$expected_redacted_lines ) );
		
		for ( my $i = 0; $i < scalar( @$expected_redacted_lines ); $i++ )
		{
			# Get the redacted line.
			my $redacted_line = $parsed_stack_trace->[$i]->get_redacted_line();
			chomp( $redacted_line );
			
			# Get the expected result, and remove any tabs,
			# which are used for formatting in the test array.
			my $expected = $expected_redacted_lines->[$i];
			$expected =~ s/\t+//g;
			
			is(
				$redacted_line,
				$expected,
				"(caller $i) The line is redacted and indented correctly.",
			);
		}
	},
);

