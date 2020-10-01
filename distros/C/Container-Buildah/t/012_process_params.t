#!/usr/bin/perl
# 012_process_params.t - tests for Container::Buildah::process_params()

use strict;
use warnings;
use autodie;

use Test::More;
use Carp qw(croak);
use Data::Dumper;
use Container::Buildah;

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/010_config.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# number of digits in test count (for text formatting)
my $test_digits = 2; # default to 2, count later

# test Container::Buildah::Subcommand::process_params()
sub test_process_params
{
	my $cb = shift;
	my $number = shift; # test group number
	my $group = shift; # hash structure of test group parameters

	# loop through tests in group
	foreach my $test (@{$group->{tests}}) {
		# generate name of test set including test group number
		(exists $test->{name})
			or croak "name not provided for test #$number";
		my $test_set = sprintf("%0".$test_digits."d %s", $number, $test->{name});

		# run test in exception handling wrapper
		my ($extracted, @args);
		eval {
			($extracted, @args) = Container::Buildah::process_params($group->{defs} // {}, $test->{params} // {});
		};
		my $exception = $@;
		if ($exception) {
			($debug_level>0) and warn "exception: ".Dumper($exception);
		}

		# process results of test
		if (not exists $test->{expected_exception}) {
			# test: exception not expected
			is($exception, '', "$test_set: no exceptions");

			# test: check args
			if (exists $test->{args}) {
				if (ref $test->{args} ne "ARRAY") {
					croak "test $test_set: args must be an array";
				}
				($debug_level>0) and warn "args = ".join(" ", @args);
				is_deeply(\@args, $test->{args}, "$test_set: args are as expected");
			}
			
			# test: check extracted
			if (exists $test->{extracted}) {
				if (ref $test->{extracted} ne "HASH") {
					croak "test $test_set: extracted must be a hash";
				}
				is_deeply($test->{extracted}, $extracted, "$test_set: extracted values are as expected");
			}
		} else {
			# exception expected
			my $expected_exception = $test->{expected_exception};
			like($exception, qr/$expected_exception/, "$test_set: expected exception");
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
				foreach my $argname (qw(args extracted)) {
					if (exists $test->{$argname}) {
						$total++;
					}
				}
			}
		}
	}
	return $total;
}

# test fixtures
my @tests = (
	{
		defs => {extract => {}},
		tests => [
			{
				name => "wrong type for extract",
				expected_exception => "process_params parameter 'extract' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_init => {}},
		tests => [
			{
				name => "wrong type for arg_init",
				expected_exception => "process_params parameter 'arg_init' must be scalar or array, got HASH",
			},
		],
	},
	{
		defs => {exclusive => {}},
		tests => [
			{
				name => "wrong type for exclusive",
				expected_exception => "process_params parameter 'exclusive' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_flag => {}},
		tests => [
			{
				name => "wrong type for arg_flag",
				expected_exception => "process_params parameter 'arg_flag' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_flag_str => {}},
		tests => [
			{
				name => "wrong type for arg_flag_str",
				expected_exception => "process_params parameter 'arg_flag_str' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_str => {}},
		tests => [
			{
				name => "wrong type for arg_str",
				expected_exception => "process_params parameter 'arg_str' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_array => {}},
		tests => [
			{
				name => "wrong type for arg_array",
				expected_exception => "process_params parameter 'arg_array' must be an array, got HASH",
			},
		],
	},
	{
		defs => {arg_list => {}},
		tests => [
			{
				name => "wrong type for arg_list",
				expected_exception => "process_params parameter 'arg_list' must be an array, got HASH",
			},
		],
	},
	{
		defs => {},
		tests => [
			{
				name => "args empty",
				args => [],
			},
		],
	},
	{
		defs => {},
		tests => [
			{
				name => "excess args",
				params => {foo => 1},
				expected_exception => "received undefined parameters: foo",
			},
		],
	},
	{
		defs => { extract => [qw(opt1 opt2)]},
		tests => [
			{
				name => "extract 1 arg",
				params => {opt1 => "foo"},
				extracted => {opt1 => "foo"},
			},
			{
				name => "extract 2 args",
				params => {opt1 => "foo", opt2 => "bar"},
				extracted => {opt1 => "foo", opt2 => "bar"},
			},
			{
				name => "extract array",
				params => {opt1 => [qw(foo bar)]},
				extracted => {opt1 => [qw(foo bar)]},
			},
			{
				name => "extract hash",
				params => {opt1 => {foo => 1, bar => 1}},
				extracted => {opt1 => {foo => 1, bar => 1}},
			},
		],
	},
	{
		defs => {arg_init => [qw(--add-history)]},
		tests => [
			{
				name => "arg_init",
				args => [qw(--add-history)],
			},
		],
	},
	{
		defs => {arg_flag => [qw(all)], exclusive => [qw(all)]},
		tests => [
			{
				name => "exclusive flag",
				params => {all => 1},
				args => [qw(--all)],
			},
			{
				name => "exclusive flag fail",
				params => {all => 1, extra => "foo"},
				expected_exception => "parameter 'all' is exclusive - cannot be passed with other parameters",
			},
		],
	},
	{
		defs => {arg_flag_str => [qw(flag)]},
		tests => [
			{
				name => "flag string true",
				params => {flag => "true"},
				args => [qw(--flag true)],
			},
			{
				name => "flag string false",
				params => {flag => "false"},
				args => [qw(--flag false)],
			},
			{
				name => "flag string fail",
				params => {flag => "foo"},
				expected_exception => "parameter 'flag' must be 'true' or 'false', got 'foo'",
			},
		],
	},
	{
		defs => {arg_str => [qw(opt1 opt2)]},
		tests => [
			{
				name => "string option",
				params => {opt1 => "foo"},
				args => [qw(--opt1 foo)],
			},
			{
				name => "string option multiple",
				params => {opt1 => "foo", opt2 => "bar"},
				args => [qw(--opt1 foo --opt2 bar)],
			},
			{
				name => "string fail",
				params => {opt1 => {}},
				expected_exception => "parameter 'opt1' must be scalar, got HASH",
			},
		],
	},
	{
		defs => {arg_array => [qw(opt)]},
		tests => [
			{
				name => "array",
				params => {opt => [qw(foo bar)]},
				args => [qw(--opt foo --opt bar)],
			},
			{
				name => "array as string",
				params => {opt => "foo"},
				args => [qw(--opt foo)],
			},
			{
				name => "array fail",
				params => {opt => {}},
				expected_exception => "parameter 'opt' must be scalar or array, got HASH",
			},
		],
	},
	{
		defs => {arg_list => [qw(list)]},
		tests => [
			{
				name => "list",
				params => {list => [qw(foo bar)]},
				args => ['--list', '[ "foo", "bar" ]'],
			},
			{
				name => "list as string",
				params => {list => "foo"},
				args => [qw(--list foo)],
			},
			{
				name => "list fail",
				params => {list => {}},
				expected_exception => "parameter 'list' must be scalar or array, got HASH",
			},
		],
	},
);

# set expected number of tests
my $test_total = count_tests(@tests);
plan tests => $test_total;
$test_digits = length("".$test_total);

# config for testing
Container::Buildah::init_config(
        basename => "process_params_test",
        testing_skip_yaml => 1,
);

# run tests
my $cb = Container::Buildah->instance(($debug_level ? (debug => $debug_level) : ()));
($debug_level>0) and warn Dumper(\@tests);
{
	for (my $i=0; $i<scalar @tests; $i++) {
		test_process_params($cb, $i+1, $tests[$i]);
	}
}
1;
