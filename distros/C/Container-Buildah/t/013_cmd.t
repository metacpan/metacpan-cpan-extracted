#!/usr/bin/perl
# 013_cmd.t - test running commands with cmd() method

use strict;
use warnings;
use autodie;

use Test::More;
use Carp qw(croak);
use Container::Buildah;
use Data::Dumper;

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/011_prog.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# number of digits in test count (for text formatting)
my $test_digits = 2; # default to 2, count later

# test Container::Buildah::Subcommand::cmd()
my ($zero_flag, $nonzero_flag, $nonzero_value);
sub test_cmd
{
	my $cb = shift;
	my $number = shift; # test group number
	my $group = shift; # hash structure of test group parameters

	# loop through tests in group
	foreach my $test (@{$group->{tests}}) {
		$zero_flag = $nonzero_flag = 0;
		$nonzero_value = undef;
		my $opts = $group->{opts} // {};
		$opts->{name} = 'test_cmd';

		# generate name of test set including test group number
		(exists $test->{name})
			or croak "name not provided for test #$number";
		my $test_set = sprintf("%0".$test_digits."d %s", $number, $test->{name});

		# run test in exception handling wrapper
		my ($outstr, $retcode);
		if (not exists $test->{args}) {
			croak "missing args for test #$number";
		}
		if (ref $test->{args} ne "ARRAY") {
			croak "wrong type for args on test #$number - must be an array ref, got "
				.(ref $test->{args} ? ref $test->{args} : "scalar");
		}
		if (exists $test->{retcode}) {
			$opts->{save_retcode} = \$retcode;
		}
		eval {
			$outstr = $cb->cmd($opts, @{$test->{args}});
		};
		my $exception = $@;
		if ($exception) {
			($debug_level>0) and warn "exception: ".Dumper($exception);
		}

		# process results of test
		if (not exists $test->{expected_exception}) {
			# test: exception not expected
			is($exception, '', "$test_set: no exceptions");

			if (exists $test->{outstr}) {
				like($outstr, qr/$test->{outstr}/, "$test_set: output text");
			}
		} else {
			# exception expected
			my $expected_exception = $test->{expected_exception};
			like($exception, qr/$expected_exception/, "$test_set: expected exception");
		}

		# check return code
		if (exists $test->{retcode}) {
			is($retcode, $test->{retcode}, "$test_set: return code");
		}

		# return-code callback tests: test callbacks for zero flag, nonzero flag & nonzero value
		if ($test->{nonzero_set} // 0) {
			is($nonzero_flag, 1, "$test_set: nonzero flag set");
		}
		if ($test->{nonzero_unset} // 0) {
			is($nonzero_flag, 0, "$test_set: nonzero flag unset");
		}
		if ($test->{zero_set} // 0) {
			is($zero_flag, 1, "$test_set: zero flag set");
		}
		if ($test->{zero_unset} // 0) {
			is($zero_flag, 0, "$test_set: zero flag unset");
		}
		if (exists $test->{nonzero_value}) {
			is($nonzero_value, $test->{nonzero_value}, "$test_set: nonzero value");
		}
	}
}

# count tests for test plan
sub count_tests
{
	my @groups = @_;
	my $total = 0;
	foreach my $group (@groups) {
		foreach my $test (@{$group->{tests}}) {
			$total++;
			if (not exists $test->{expected_excetion}) {
				foreach my $argname (qw(outstr)) {
					if (exists $test->{$argname}) {
						$total++;
					}
				}
			}
			foreach my $argname (qw(retcode nonzero_value nonzero_set nonzero_unset zero_set zero_unset)) {
				if (exists $test->{$argname}) {
					$total++;
				}
			}
		}
	}
	return $total;
}

#
# main
#

# config for testing
Container::Buildah::init_config(
        basename => "cmd_test",
        testing_skip_yaml => 1,
);
my $cb = Container::Buildah->instance(($debug_level ? (debug => $debug_level) : ()));

## test fixtures
my @tests = (
	{
		opts => {},
		tests => [
			{
				name => "run true",
				args => [Container::Buildah::prog("true")],
				retcode => 0,
			},
			{
				name => "run false",
				args => [Container::Buildah::prog("false")],
				expected_exception => '^test_cmd: non-zero status \(1\) from cmd',
				retcode => 1,
			},
			{
				name => "run sh exit 2",
				args => ['/bin/sh', '-c', 'exit 2'],
				expected_exception => '^test_cmd: non-zero status \(2\) from cmd',
				retcode => 2,
			},
			{
				name => "nonexistent command",
				args => ['/nonexistent/path/to/bin/foo'],
				expected_exception => '^test_cmd: file not found: /nonexistent/path/to/bin/foo',
			},
			{
				name => "undef disallowed in args",
				args => [Container::Buildah::prog("true"), undef],
				expected_exception => '^test_cmd: disallow_undef: found undefined value in parameter list item 1:',
			},
		],
	},
	{
		opts => {
			capture_output => 1,
		},
		tests => [
			{
				name => "capture echo empty",
				args => [Container::Buildah::prog("echo")],
				retcode => 0,
				outstr => '^$',
			},
			{
				name => "capture echo string",
				args => [Container::Buildah::prog("echo"), "foo"],
				retcode => 0,
				outstr => "foo",
			},
		],
	},
	{
		opts => {
			nonzero => sub { $nonzero_flag = 1; $nonzero_value = shift; },
			zero => sub { $zero_flag = 1; },
		},
		tests => [
			{
				name => "callback with return 0",
				args => [Container::Buildah::prog("true")],
				retcode => 0,
				zero_set => 1,
				nonzero_unset => 1,
			},
			{
				name => "callback with return 1",
				args => [Container::Buildah::prog("false")],
				retcode => 1,
				nonzero_set => 1,
				zero_unset => 1,
				nonzero_value => 1,
			},
			{
				name => "callback with return 2",
				args => ['/bin/sh', '-c', 'exit 2'],
				retcode => 2,
				nonzero_set => 1,
				zero_unset => 1,
				nonzero_value => 2,
			},
		],
	},
);
($debug_level>0) and warn Dumper(\@tests);

# set expected number of tests
my $test_total = count_tests(@tests);
plan tests => $test_total;
$test_digits = length("".$test_total);

# run tests
{
	for (my $i=0; $i<scalar @tests; $i++) {
		test_cmd($cb, $i+1, $tests[$i]);
	}
}
1;
